// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./DZStudentAnswer.sol";
import "./Errors.sol";

abstract contract DZScoreManager is DZStudentAnswer {
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
        if(!exams[_exam_id].is_active) revert Errors.E301();
        if(_score > 100) revert Errors.E004();
        if(_student_id == 0) revert Errors.E003();
        if(scores[_student_id][_exam_id].student_id != 0) revert Errors.E502();

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

    function createScoreFromAnswer(uint256 _student_id, uint256 _exam_id) 
        public 
        onlyRole(LECTURER_ROLE) 
    {
        if(!studentAnswers[_student_id][_exam_id].is_submitted) revert Errors.E603();
        if(!studentAnswers[_student_id][_exam_id].is_scored) revert Errors.E604();
        if(scores[_student_id][_exam_id].student_id != 0) revert Errors.E502();

        uint256 answerScore = studentAnswers[_student_id][_exam_id].score;
        
        scores[_student_id][_exam_id] = Score({
            student_id: _student_id,
            exam_id: _exam_id,
            score: answerScore,
            graded_by: studentAnswers[_student_id][_exam_id].scored_by,
            created_at: block.timestamp,
            updated_at: block.timestamp,
            is_final: false
        });

        examScores[_exam_id].push(_student_id);
        emit ScoreStored(_student_id, _exam_id, answerScore, msg.sender);
    }

    function updateScore(
        uint256 _student_id,
        uint256 _exam_id,
        uint256 _new_score
    ) public onlyRole(LECTURER_ROLE) {
        if(!exams[_exam_id].is_active) revert Errors.E301();
        if(_new_score > 100) revert Errors.E004();
        if(scores[_student_id][_exam_id].student_id == 0) revert Errors.E501();
        if(scores[_student_id][_exam_id].is_final) revert Errors.E503();

        uint256 old_score = scores[_student_id][_exam_id].score;
        scores[_student_id][_exam_id].score = _new_score;
        scores[_student_id][_exam_id].updated_at = block.timestamp;

        emit ScoreUpdated(_student_id, _exam_id, old_score, _new_score, msg.sender);
    }

    function finalizeScore(uint256 _student_id, uint256 _exam_id) public onlyRole(LECTURER_ROLE) {
        if(!exams[_exam_id].is_active) revert Errors.E301();
        if(scores[_student_id][_exam_id].student_id == 0) revert Errors.E501();
        if(scores[_student_id][_exam_id].is_final) revert Errors.E503();

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
        if(!(hasRole(ADMIN_ROLE, msg.sender) || hasRole(LECTURER_ROLE, msg.sender))) revert Errors.E101();
        return examScores[_exam_id];
    }
}