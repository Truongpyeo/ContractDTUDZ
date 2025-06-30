// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./DZExamManager.sol";

abstract contract DZStudentAnswer is DZExamManager {
    struct StudentAnswer {
        uint256 student_id;
        uint256 exam_id;
        string content;         // Hash của tất cả câu trả lời
        uint256 score;          // Điểm sau khi chấm (default = 0)
        uint256 submitted_at;   // Thời gian nộp bài
        address submitted_by;   // Địa chỉ nộp bài
        uint256 scored_at;      // Thời gian chấm điểm
        address scored_by;      // Giảng viên chấm điểm
        bool is_submitted;      // Đã nộp bài chưa
        bool is_scored;         // Đã chấm điểm chưa
    }

    mapping(uint256 => mapping(uint256 => StudentAnswer)) public studentAnswers;
    mapping(uint256 => uint256[]) public examSubmissions; // exam_id => student_ids[]

    event AnswerSubmitted(
        uint256 indexed student_id,
        uint256 indexed exam_id,
        string content,
        address indexed submitted_by,
        uint256 submitted_at
    );

    event AnswerScored(
        uint256 indexed student_id,
        uint256 indexed exam_id,
        uint256 score,
        address indexed scored_by,
        uint256 scored_at
    );

    event AnswerUpdated(
        uint256 indexed student_id,
        uint256 indexed exam_id,
        uint256 old_score,
        uint256 new_score,
        address indexed updated_by
    );

    function submitAnswer(uint256 _student_id, uint256 _exam_id, string memory _content) 
        public 
        onlyRole(STUDENT_ROLE) 
    {
        if(_student_id == 0) revert Errors.E003();
        if(!exams[_exam_id].is_active) revert Errors.E301();
        if(exams[_exam_id].is_locked) revert Errors.E303();
        if(studentAddresses[_student_id] != msg.sender) revert Errors.E605();
        if(bytes(_content).length == 0) revert Errors.E002();
        if(studentAnswers[_student_id][_exam_id].is_submitted) revert Errors.E602();

        studentAnswers[_student_id][_exam_id] = StudentAnswer({
            student_id: _student_id,
            exam_id: _exam_id,
            content: _content,
            score: 0,
            submitted_at: block.timestamp,
            submitted_by: msg.sender,
            scored_at: 0,
            scored_by: address(0),
            is_submitted: true,
            is_scored: false
        });

        examSubmissions[_exam_id].push(_student_id);

        emit AnswerSubmitted(_student_id, _exam_id, _content, msg.sender, block.timestamp);
    }

    function submitMyAnswer(uint256 _exam_id, string memory _content) 
        public 
        onlyRole(STUDENT_ROLE) 
    {
        uint256 studentId = addressToStudentId[msg.sender];
        if(studentId == 0) revert Errors.E204();
        submitAnswer(studentId, _exam_id, _content);
    }

    function scoreAnswer(uint256 _student_id, uint256 _exam_id, uint256 _score) 
        public 
        onlyRole(LECTURER_ROLE) 
    {
        if(!exams[_exam_id].is_active) revert Errors.E301();
        if(_score > 100) revert Errors.E004();
        if(!studentAnswers[_student_id][_exam_id].is_submitted) revert Errors.E603();

        uint256 oldScore = studentAnswers[_student_id][_exam_id].score;
        
        studentAnswers[_student_id][_exam_id].score = _score;
        studentAnswers[_student_id][_exam_id].scored_at = block.timestamp;
        studentAnswers[_student_id][_exam_id].scored_by = msg.sender;
        studentAnswers[_student_id][_exam_id].is_scored = true;

        if (oldScore != _score) {
            emit AnswerUpdated(_student_id, _exam_id, oldScore, _score, msg.sender);
        }

        emit AnswerScored(_student_id, _exam_id, _score, msg.sender, block.timestamp);
    }

    function updateAnswerScore(uint256 _student_id, uint256 _exam_id, uint256 _new_score) 
        public 
        onlyRole(LECTURER_ROLE) 
    {
        if(!exams[_exam_id].is_active) revert Errors.E301();
        if(_new_score > 100) revert Errors.E004();
        if(!studentAnswers[_student_id][_exam_id].is_submitted) revert Errors.E603();
        if(!studentAnswers[_student_id][_exam_id].is_scored) revert Errors.E604();

        uint256 oldScore = studentAnswers[_student_id][_exam_id].score;
        if(oldScore == _new_score) revert Errors.E001();

        studentAnswers[_student_id][_exam_id].score = _new_score;
        studentAnswers[_student_id][_exam_id].scored_at = block.timestamp;
        studentAnswers[_student_id][_exam_id].scored_by = msg.sender;

        emit AnswerUpdated(_student_id, _exam_id, oldScore, _new_score, msg.sender);
    }

    function getStudentAnswer(uint256 _student_id, uint256 _exam_id) 
        public 
        view 
        returns (StudentAnswer memory) 
    {
        if(!(hasRole(LECTURER_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender) || (studentAddresses[_student_id] == msg.sender && hasRole(STUDENT_ROLE, msg.sender)))) revert Errors.E101();
        
        require(studentAnswers[_student_id][_exam_id].is_submitted, "Answer not found");
        return studentAnswers[_student_id][_exam_id];
    }

    function getMyAnswer(uint256 _exam_id) 
        public 
        view 
        onlyRole(STUDENT_ROLE) 
        returns (StudentAnswer memory) 
    {
        uint256 studentId = addressToStudentId[msg.sender];
        if(studentId == 0) revert Errors.E204();
        if(!studentAnswers[studentId][_exam_id].is_submitted) revert Errors.E601();
        return studentAnswers[studentId][_exam_id];
    }

    function getExamSubmissions(uint256 _exam_id) 
        public 
        view 
        returns (uint256[] memory) 
    {
        if(!(hasRole(LECTURER_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender))) revert Errors.E101();
        return examSubmissions[_exam_id];
    }

    function hasSubmittedAnswer(uint256 _student_id, uint256 _exam_id) 
        public 
        view 
        returns (bool) 
    {
        return studentAnswers[_student_id][_exam_id].is_submitted;
    }

    function getAnswerScore(uint256 _student_id, uint256 _exam_id) 
        public 
        view 
        returns (uint256) 
    {
        if(!(hasRole(LECTURER_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender) || (studentAddresses[_student_id] == msg.sender && hasRole(STUDENT_ROLE, msg.sender)))) revert Errors.E101();
        if(!studentAnswers[_student_id][_exam_id].is_submitted) revert Errors.E601();
        return studentAnswers[_student_id][_exam_id].score;
    }
} 