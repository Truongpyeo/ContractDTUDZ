// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./DZScoreManager.sol";

import "./Errors.sol";

abstract contract DZReviewManager is DZScoreManager {
    struct ReviewRequest {
        uint256 student_id;
        uint256 exam_id;
        uint256 request_date;
        string status;
        uint256 old_score;
        uint256 new_score;
        string reason;
        address reviewer;
        uint256 reviewed_at;
        bool is_processed;
    }

    mapping(uint256 => mapping(uint256 => ReviewRequest)) public reviewRequests;

    event ReviewRequested(
        uint256 indexed student_id,
        uint256 indexed exam_id,
        string status,
        uint256 old_score,
        string reason
    );
    event ReviewProcessed(
        uint256 indexed student_id,
        uint256 indexed exam_id,
        string status,
        uint256 new_score,
        address indexed reviewer
    );

    function storeReviewRequest(uint256 _student_id, uint256 _exam_id, string memory _reason) public onlyRole(STUDENT_ROLE) {
        if(studentAddresses[_student_id] != msg.sender) revert Errors.E101();
        if(!exams[_exam_id].is_active) revert Errors.E301();
        if(scores[_student_id][_exam_id].student_id == 0) revert Errors.E501();
        if(reviewRequests[_student_id][_exam_id].is_processed) revert Errors.E703();
        if(bytes(_reason).length == 0) revert Errors.E002();

        uint256 current_score = scores[_student_id][_exam_id].score;

        reviewRequests[_student_id][_exam_id] = ReviewRequest({
            student_id: _student_id,
            exam_id: _exam_id,
            request_date: block.timestamp,
            status: "PENDING",
            old_score: current_score,
            new_score: 0,
            reason: _reason,
            reviewer: address(0),
            reviewed_at: 0,
            is_processed: false
        });

        emit ReviewRequested(_student_id, _exam_id, "PENDING", current_score, _reason);
    }

    function createMyReviewRequest(uint256 _exam_id, string memory _reason) public onlyRole(STUDENT_ROLE) {
        uint256 studentId = addressToStudentId[msg.sender];
        if(studentId == 0) revert Errors.E204();
        storeReviewRequest(studentId, _exam_id, _reason);
    }

    function processReviewRequest(
        uint256 _student_id,
        uint256 _exam_id,
        string memory _review_status,
        uint256 _new_score
    ) public onlyRole(LECTURER_ROLE) {
        if(!exams[_exam_id].is_active) revert Errors.E301();
        if(reviewRequests[_student_id][_exam_id].student_id == 0) revert Errors.E701();
        if(reviewRequests[_student_id][_exam_id].is_processed) revert Errors.E703();
        if(!(keccak256(abi.encodePacked(_review_status)) == keccak256("APPROVED") || keccak256(abi.encodePacked(_review_status)) == keccak256("REJECTED"))) revert Errors.E704();

        if (keccak256(abi.encodePacked(_review_status)) == keccak256("APPROVED")) {
            if(_new_score > 100) revert Errors.E004();
        }

        reviewRequests[_student_id][_exam_id].status = _review_status;
        reviewRequests[_student_id][_exam_id].new_score = _new_score;
        reviewRequests[_student_id][_exam_id].reviewer = msg.sender;
        reviewRequests[_student_id][_exam_id].reviewed_at = block.timestamp;
        reviewRequests[_student_id][_exam_id].is_processed = true;

        if (keccak256(abi.encodePacked(_review_status)) == keccak256("APPROVED")) {
            uint256 old_score = scores[_student_id][_exam_id].score;
            scores[_student_id][_exam_id].score = _new_score;
            scores[_student_id][_exam_id].updated_at = block.timestamp;
            emit ScoreUpdated(_student_id, _exam_id, old_score, _new_score, msg.sender);
        }

        emit ReviewProcessed(_student_id, _exam_id, _review_status, _new_score, msg.sender);
    }

    function getReviewRequest(uint256 _student_id, uint256 _exam_id)
        public
        view
        returns (ReviewRequest memory)
    {
        if(!(hasRole(LECTURER_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender) || (studentAddresses[_student_id] == msg.sender && hasRole(STUDENT_ROLE, msg.sender)))) revert Errors.E101();

        return reviewRequests[_student_id][_exam_id];
    }

    function getMyReviewRequest(uint256 _exam_id)
        public
        view
        onlyRole(STUDENT_ROLE)
        returns (ReviewRequest memory)
    {
        uint256 studentId = addressToStudentId[msg.sender];
        if(studentId == 0) revert Errors.E204();
        return reviewRequests[studentId][_exam_id];
    }
}