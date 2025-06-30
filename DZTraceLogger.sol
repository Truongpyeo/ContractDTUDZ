// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./DZCertificate.sol";

abstract contract DZTraceLogger is DZCertificate {
    struct TraceRecord {
        uint256 timestamp;
        address caller;
        string action;
        uint256 target_id;
        string details;
    }

    mapping(uint256 => TraceRecord[]) public traces;
    uint256 private _traceCounter;

    event TraceRecorded(
        uint256 indexed entity_id,
        address indexed caller,
        string action,
        uint256 target_id,
        string details,
        uint256 timestamp
    );

    function addTrace(
        uint256 _entity_id,
        string memory _action,
        uint256 _target_id,
        string memory _details
    ) internal {
        traces[_entity_id].push(TraceRecord({
            timestamp: block.timestamp,
            caller: msg.sender,
            action: _action,
            target_id: _target_id,
            details: _details
        }));

        emit TraceRecorded(
            _entity_id,
            msg.sender,
            _action,
            _target_id,
            _details,
            block.timestamp
        );
    }

    function getTraces(uint256 _entity_id)
        public
        view
        returns (TraceRecord[] memory)
    {
        if(!(hasRole(ADMIN_ROLE, msg.sender) || hasRole(LECTURER_ROLE, msg.sender))) revert Errors.E101();
        return traces[_entity_id];
    }

    function getTraceCount(uint256 _entity_id) public view returns (uint256) {
        return traces[_entity_id].length;
    }
}