// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract ETEEPay {
    using SafeERC20 for IERC20;

    error InvalidToken();
    error InvalidProvider();
    error InvalidAmount();
    error InvalidTreasury();
    error JobAlreadySettled(uint256 jobId);

    uint256 public constant PROVIDER_BPS = 9_500;
    uint256 public constant TREASURY_BPS = 500;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    IERC20 public immutable TOKEN;
    address public immutable PROTOCOL_TREASURY;

    mapping(uint256 => bool) public settledJobs;

    event JobSettled(
        uint256 indexed jobId,
        address indexed payer,
        address indexed provider,
        uint256 providerAmount,
        uint256 treasuryAmount
    );

    constructor(address token_, address protocolTreasury_) {
        if (token_ == address(0)) revert InvalidToken();
        if (protocolTreasury_ == address(0)) revert InvalidTreasury();

        TOKEN = IERC20(token_);
        PROTOCOL_TREASURY = protocolTreasury_;
    }

    function settleJob(address provider, uint256 jobId, uint256 amount) external {
        if (provider == address(0)) revert InvalidProvider();
        if (amount == 0) revert InvalidAmount();
        if (settledJobs[jobId]) revert JobAlreadySettled(jobId);

        settledJobs[jobId] = true;

        uint256 treasuryAmount = (amount * TREASURY_BPS) / BPS_DENOMINATOR;
        uint256 providerAmount = amount - treasuryAmount;

        TOKEN.safeTransferFrom(msg.sender, provider, providerAmount);
        TOKEN.safeTransferFrom(msg.sender, PROTOCOL_TREASURY, treasuryAmount);

        emit JobSettled(jobId, msg.sender, provider, providerAmount, treasuryAmount);
    }
}
