// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./DZExamManager.sol";

abstract contract DZScoreManager is DZExamManager {
    struct Score {
        uint256 student_id;
        uint256 exam_id;
        uint256 score;
        address graded_by;
        uint256 created_at;
        uint256 updated_at;
        bool is_final;
    }

    mapping(uint256 => mapping(uint256 => Score)) public scores;
    mapping(uint256 => uint256[]) public examScores;

    event ScoreStored(
        uint256 indexed student_id,
        uint256 indexed exam_id,
        uint256 score,
        address indexed graded_by
    );
    event ScoreUpdated(
        uint256 indexed student_id,
        uint256 indexed exam_id,
        uint256 old_score,
        uint256 new_score,
        address indexed updated_by
    );
    event ScoreFinalized(
        uint256 indexed student_id,
        uint256 indexed exam_id,
        address indexed finalized_by
    );

    function storeScore(
        uint256 _student_id,
        uint256 _exam_id,
        uint256 _score
    ) public onlyRole(LECTURER_ROLE) {
        require(exams[_exam_id].is_active, "Exam does not exist");
        require(_score <= 100, "Score must be <= 100");
        require(_student_id > 0, "Invalid student ID");
        require(scores[_student_id][_exam_id].student_id == 0, "Score already exists");

        scores[_student_id][_exam_id] = Score({
            student_id: _student_id,
            exam_id: _exam_id,
            score: _score,
            graded_by: msg.sender,
            created_at: block.timestamp,
            updated_at: block.timestamp,
            is_final: false
        });

        examScores[_exam_id].push(_student_id);
        emit ScoreStored(_student_id, _exam_id, _score, msg.sender);
    }

    function updateScore(
        uint256 _student_id,
        uint256 _exam_id,
        uint256 _new_score
    ) public onlyRole(LECTURER_ROLE) {
        require(exams[_exam_id].is_active, "Exam does not exist");
        require(_new_score <= 100, "Score must be <= 100");
        require(scores[_student_id][_exam_id].student_id != 0, "Score does not exist");
        require(!scores[_student_id][_exam_id].is_final, "Score is finalized");

        uint256 old_score = scores[_student_id][_exam_id].score;
        scores[_student_id][_exam_id].score = _new_score;
        scores[_student_id][_exam_id].updated_at = block.timestamp;

        emit ScoreUpdated(_student_id, _exam_id, old_score, _new_score, msg.sender);
    }

    function finalizeScore(uint256 _student_id, uint256 _exam_id) public onlyRole(LECTURER_ROLE) {
        require(exams[_exam_id].is_active, "Exam does not exist");
        require(scores[_student_id][_exam_id].student_id != 0, "Score does not exist");
        require(!scores[_student_id][_exam_id].is_final, "Already finalized");

        scores[_student_id][_exam_id].is_final = true;
        emit ScoreFinalized(_student_id, _exam_id, msg.sender);
    }

    function getScore(uint256 _student_id, uint256 _exam_id)
        public
        view
        returns (
            uint256 student_id,
            uint256 exam_id,
            uint256 score,
            address graded_by,
            uint256 created_at,
            uint256 updated_at,
            bool is_final
        )
    {
        Score memory scoreData = scores[_student_id][_exam_id];
        return (
            scoreData.student_id,
            scoreData.exam_id,
            scoreData.score,
            scoreData.graded_by,
            scoreData.created_at,
            scoreData.updated_at,
            scoreData.is_final
        );
    }

    function getExamScores(uint256 _exam_id) public view returns (uint256[] memory) {
        require(
            hasRole(ADMIN_ROLE, msg.sender) || hasRole(LECTURER_ROLE, msg.sender),
            "Access denied"
        );
        return examScores[_exam_id];
    }
}
