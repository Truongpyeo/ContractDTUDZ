// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DZAccessControl.sol";

contract StudentAnswer is DZAccessControl {
    struct Answer {
        uint256 student_id;
        uint256 exam_id;
        string content; // Hash of all answers
        uint256 score;  // Default = 0
        bool submitted;
    }

    // Mapping: student_id => exam_id => Answer
    mapping(uint256 => mapping(uint256 => Answer)) private _answers;

    // Event: Nộp bài và chấm điểm
    event AnswerSubmitted(uint256 indexed student_id, uint256 indexed exam_id, string content);
    event ScoreUpdated(uint256 indexed student_id, uint256 indexed exam_id, uint256 newScore);

    /// @notice Sinh viên nộp bài (chỉ 1 lần cho mỗi exam_id)
    function submitAnswer(uint256 student_id, uint256 exam_id, string calldata content) external onlyRole(STUDENT_ROLE) {
        require(!_answers[student_id][exam_id].submitted, "Already submitted");

        _answers[student_id][exam_id] = Answer({
            student_id: student_id,
            exam_id: exam_id,
            content: content,
            score: 0,
            submitted: true
        });

        emit AnswerSubmitted(student_id, exam_id, content);
    }

    /// @notice Giảng viên chấm điểm
    function updateScore(uint256 student_id, uint256 exam_id, uint256 newScore) external onlyRole(LECTURER_ROLE) {
        require(_answers[student_id][exam_id].submitted, "Not submitted yet");

        _answers[student_id][exam_id].score = newScore;

        emit ScoreUpdated(student_id, exam_id, newScore);
    }

    /// @notice Truy xuất bài làm
    function getAnswer(uint256 student_id, uint256 exam_id) external view returns (Answer memory) {
        return _answers[student_id][exam_id];
    }

    /// @notice Truy xuất điểm
    function getScore(uint256 student_id, uint256 exam_id) external view returns (uint256) {
        return _answers[student_id][exam_id].score;
    }

    /// @notice Kiểm tra đã nộp hay chưa
    function hasSubmitted(uint256 student_id, uint256 exam_id) external view returns (bool) {
        return _answers[student_id][exam_id].submitted;
    }
}
