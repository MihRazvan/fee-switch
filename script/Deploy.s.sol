// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {ETEEPay} from "src/ETEEPay.sol";
import {MockERC20} from "src/MockERC20.sol";

contract Deploy is Script {
    function run() external returns (MockERC20 token, ETEEPay feeSwitch) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 initialSupply = vm.envUint("INITIAL_SUPPLY");
        address protocolTreasury = vm.envAddress("PROTOCOL_TREASURY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        token = new MockERC20(deployer, initialSupply);
        feeSwitch = new ETEEPay(address(token), protocolTreasury);

        vm.stopBroadcast();

        console2.log("Deployer:", deployer);
        console2.log("MockERC20:", address(token));
        console2.log("ETEEPay:", address(feeSwitch));
        console2.log("Protocol Treasury:", protocolTreasury);
    }
}
