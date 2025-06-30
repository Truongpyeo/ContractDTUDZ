// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library Errors {
    // === INPUT VALIDATION ERRORS ===
    error E001(); // Invalid input parameter
    error E002(); // Empty string not allowed  
    error E003(); // Invalid ID (must be > 0)
    error E004(); // Invalid score (must be 0-100)
    error E005(); // Invalid address (zero address)

    // === ACCESS CONTROL ERRORS ===
    error E101(); // Not authorized  
    error E102(); // Only admin allowed
    error E103(); // Only lecturer allowed
    error E104(); // Only student allowed
    error E105(); // Only employer allowed

    // === STUDENT MANAGEMENT ERRORS ===
    error E201(); // Student not found
    error E202(); // Student already exists
    error E203(); // Student address already set
    error E204(); // Student not registered

    // === EXAM MANAGEMENT ERRORS ===
    error E301(); // Exam not found
    error E302(); // Exam already exists  
    error E303(); // Exam is locked
    error E304(); // Exam already locked
    error E305(); // Only exam creator can perform this action

    // === TEST MANAGEMENT ERRORS ===
    error E401(); // Test not found
    error E402(); // Test already exists
    error E403(); // Test is blocked
    error E404(); // Test already blocked
    error E405(); // Test is not blocked

    // === SCORE MANAGEMENT ERRORS ===
    error E501(); // Score not found
    error E502(); // Score already exists
    error E503(); // Score is finalized
    error E504(); // Score not finalized yet

    // === ANSWER MANAGEMENT ERRORS ===
    error E601(); // Answer not found
    error E602(); // Answer already submitted
    error E603(); // Answer not submitted yet
    error E604(); // Answer already scored
    error E605(); // Cannot submit for other student

    // === REVIEW REQUEST ERRORS ===
    error E701(); // Review request not found
    error E702(); // Review request already exists
    error E703(); // Review request already processed
    error E704(); // Invalid review status

    // === CERTIFICATE ERRORS ===
    error E801(); // Certificate not found
    error E802(); // Certificate already issued
    error E803(); // Certificate is revoked
    error E804(); // Certificate already revoked

    // === TRACE SYSTEM ERRORS ===
    error E901(); // No trace records found
    error E902(); // Trace access denied
}