// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {ETEEPay} from "src/ETEEPay.sol";
import {MockERC20} from "src/MockERC20.sol";

contract ETEEPayTest is Test {
    uint256 internal constant INITIAL_SUPPLY = 1_000_000e18;

    MockERC20 internal token;
    ETEEPay internal feeSwitch;

    address internal payer = makeAddr("payer");
    address internal provider = makeAddr("provider");
    address internal treasury = makeAddr("treasury");

    event JobSettled(
        uint256 indexed jobId,
        address indexed payer,
        address indexed provider,
        uint256 providerAmount,
        uint256 treasuryAmount
    );

    function setUp() public {
        token = new MockERC20(address(this), INITIAL_SUPPLY);
        feeSwitch = new ETEEPay(address(token), treasury);

        assertTrue(token.transfer(payer, 1_000e18));
    }

    function test_settleJob_splitsFundsAndMarksJobSettled() public {
        uint256 amount = 100e18;
        uint256 jobId = 1;

        vm.startPrank(payer);
        token.approve(address(feeSwitch), amount);
        feeSwitch.settleJob(provider, jobId, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(provider), 95e18);
        assertEq(token.balanceOf(treasury), 5e18);
        assertEq(token.balanceOf(payer), 900e18);
        assertTrue(feeSwitch.settledJobs(jobId));
    }

    function test_settleJob_assignsRemainderToProvider() public {
        uint256 amount = 101;
        uint256 jobId = 2;

        vm.startPrank(payer);
        token.approve(address(feeSwitch), amount);
        feeSwitch.settleJob(provider, jobId, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(provider), 96);
        assertEq(token.balanceOf(treasury), 5);
    }

    function test_settleJob_emitsEvent() public {
        uint256 amount = 100e18;
        uint256 jobId = 3;

        vm.startPrank(payer);
        token.approve(address(feeSwitch), amount);

        vm.expectEmit(address(feeSwitch));
        emit JobSettled(jobId, payer, provider, 95e18, 5e18);
        feeSwitch.settleJob(provider, jobId, amount);

        vm.stopPrank();
    }

    function test_settleJob_revertsWhenProviderIsZero() public {
        vm.prank(payer);
        vm.expectRevert(ETEEPay.InvalidProvider.selector);
        feeSwitch.settleJob(address(0), 1, 100e18);
    }

    function test_settleJob_revertsWhenAmountIsZero() public {
        vm.prank(payer);
        vm.expectRevert(ETEEPay.InvalidAmount.selector);
        feeSwitch.settleJob(provider, 1, 0);
    }

    function test_settleJob_revertsWhenJobAlreadySettled() public {
        uint256 amount = 100e18;
        uint256 jobId = 4;

        vm.startPrank(payer);
        token.approve(address(feeSwitch), amount * 2);
        feeSwitch.settleJob(provider, jobId, amount);

        vm.expectRevert(abi.encodeWithSelector(ETEEPay.JobAlreadySettled.selector, jobId));
        feeSwitch.settleJob(provider, jobId, amount);
        vm.stopPrank();
    }

    function test_constructor_revertsWhenTokenIsZero() public {
        vm.expectRevert(ETEEPay.InvalidToken.selector);
        new ETEEPay(address(0), treasury);
    }

    function test_constructor_revertsWhenTreasuryIsZero() public {
        vm.expectRevert(ETEEPay.InvalidTreasury.selector);
        new ETEEPay(address(token), address(0));
    }
}
