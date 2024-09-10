// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {RhinestoneModuleKit, ModuleKitHelpers, ModuleKitUserOp, AccountInstance} from "modulekit/ModuleKit.sol";
import {MODULE_TYPE_EXECUTOR} from "modulekit/external/ERC7579.sol";
import {ExecutionLib} from "erc7579/lib/ExecutionLib.sol";
import {RecurringExecuteModule} from "src/RecurringExecuteModule.sol";

contract RecurringExecuteModuleTest is RhinestoneModuleKit, Test {
    using ModuleKitHelpers for *;
    using ModuleKitUserOp for *;

    enum ExecutionBasis {
        Daily,
        Weekly,
        Monthly
    }

    // account and modules
    AccountInstance internal instance;
    RecurringExecuteModule internal executor;
    address target;

    function setUp() public {
        init();

        target = makeAddr("target");

        // Create the executor
        executor = new RecurringExecuteModule();
        vm.label(address(executor), "RecurringExecuteModule");

        // Create the account and install the executor
        instance = makeAccountInstance("Account");
        vm.deal(address(instance.account), 10 ether);
        instance.installModule({
            moduleTypeId: MODULE_TYPE_EXECUTOR,
            module: address(executor),
            data: abi.encode(
                ExecutionBasis.Daily,
                target,
                1 ether,
                uint8(1),
                uint8(1),
                uint8(22)
            )
        });
    }

    function testExec() public {
        console.log("Initial block timestamp:", block.timestamp);
        vm.warp(block.timestamp + 1 days + 1 hours);
        console.log("Next days block timestamp:", block.timestamp);
        console.log("isInstalled:", executor.isInitialized(instance.account));
        uint256 prevBalance = target.balance;

        // Execute the call
        // EntryPoint -> Account -> Executor -> Account -> Target
        instance.exec({
            target: address(executor),
            value: 0,
            callData: abi.encodeWithSelector(
                RecurringExecuteModule.execute.selector,
                instance.account
            )
        });
        assertEq(target.balance, prevBalance + 1 ether);
        vm.warp(block.timestamp + 1 days + 1 hours);

        executor.execute(address(instance.account));
        assertEq(target.balance, prevBalance + 2 ether);
    }
}
