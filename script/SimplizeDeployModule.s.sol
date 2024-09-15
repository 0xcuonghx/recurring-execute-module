// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

// Import modules here
import {RecurringExecuteModule} from "src/RecurringExecuteModule.sol";

/// @title DeployModuleScript
contract SimplizeDeployModule is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        new RecurringExecuteModule();

        vm.stopBroadcast();
    }
}
