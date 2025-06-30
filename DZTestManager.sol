// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./DZTraceLogger.sol";

abstract contract DZTestManager is DZTraceLogger {
    struct Tests {
        uint256 test_id;
        uint256 id_created_by;
        uint256 created_at;
        bool is_blocked;
        bool is_active;
    }

    mapping(uint256 => Tests) public tests;
    mapping(uint256 => uint256[]) public userTests;

    event TestCreated(
        uint256 indexed test_id,
        uint256 indexed id_created_by,
        uint256 created_at
    );
    event TestBlocked(uint256 indexed test_id, address indexed blocked_by);
    event TestUnblocked(uint256 indexed test_id, address indexed unblocked_by);

    function createTest(
        uint256 _test_id,
        uint256 _id_created_by
    ) public onlyRole(ADMIN_ROLE) {
        if(_test_id == 0) revert Errors.E003();
        if(_id_created_by == 0) revert Errors.E003();
        if(tests[_test_id].is_active) revert Errors.E402();

        tests[_test_id] = Tests({
            test_id: _test_id,
            id_created_by: _id_created_by,
            created_at: block.timestamp,
            is_blocked: false,
            is_active: true
        });

        userTests[_id_created_by].push(_test_id);
        emit TestCreated(_test_id, _id_created_by, block.timestamp);
    }

    function blockTest(uint256 _test_id) public onlyRole(ADMIN_ROLE) {
        if(!tests[_test_id].is_active) revert Errors.E401();
        if(tests[_test_id].is_blocked) revert Errors.E404();
        tests[_test_id].is_blocked = true;
        emit TestBlocked(_test_id, msg.sender);
    }

    function unblockTest(uint256 _test_id) public onlyRole(ADMIN_ROLE) {
        if(!tests[_test_id].is_active) revert Errors.E401();
        if(!tests[_test_id].is_blocked) revert Errors.E405();

        tests[_test_id].is_blocked = false;
        emit TestUnblocked(_test_id, msg.sender);
    }

    function getTest(
        uint256 _test_id
    )
        public
        view
        returns (
            uint256 test_id,
            uint256 id_created_by,
            uint256 created_at,
            bool is_blocked,
            bool is_active
        )
    {
        Tests memory testData = tests[_test_id];
        if(!testData.is_active) revert Errors.E401();
        return (
            testData.test_id,
            testData.id_created_by,
            testData.created_at,
            testData.is_blocked,
            testData.is_active
        );
    }

    function getUserTests(
        uint256 _user_id
    ) public view returns (uint256[] memory) {
        return userTests[_user_id];
    }
}