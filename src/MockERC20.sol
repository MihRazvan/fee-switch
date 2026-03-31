// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(address initialHolder, uint256 initialSupply) ERC20("Mock Fee Token", "MFT") {
        _mint(initialHolder, initialSupply);
    }
}
