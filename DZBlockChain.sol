// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./DZTestManager.sol";

import "./Errors.sol";

contract DZBlockChain is DZTestManager {
    constructor() {
        _initializeAccessControl(msg.sender);
    }
}
