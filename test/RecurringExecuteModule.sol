// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {RhinestoneModuleKit, ModuleKitHelpers, ModuleKitUserOp, AccountInstance} from "modulekit/ModuleKit.sol";
import {MODULE_TYPE_EXECUTOR} from "modulekit/external/ERC7579.sol";
import {ExecutionLib} from "erc7579/lib/ExecutionLib.sol";
import {RecurringExecuteModule} from "src/RecurringExecuteModule.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

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
    MockERC20 internal token;

    function setUp() public {
        init();

        instance = makeAccountInstance("Account");
        target = makeAddr("target");

        token = new MockERC20("USDC", "USDC", 18);
        vm.label(address(token), "USDC");
        token.mint(address(instance.account), 1_000_000);

        // Create the executor
        executor = new RecurringExecuteModule();
        vm.label(address(executor), "RecurringExecuteModule");

        // Create the account and install the executor
        vm.deal(address(instance.account), 10 ether);
        instance.installModule({
            moduleTypeId: MODULE_TYPE_EXECUTOR,
            module: address(executor),
            data: abi.encode(
                ExecutionBasis.Daily,
                target,
                token,
                100_000,
                uint8(1),
                uint8(1),
                uint8(22)
            )
        });
    }

    function testExec() public {
        vm.warp(block.timestamp + 1 days + 1 hours);

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

        assertEq(token.balanceOf(target), 100_000);
        assertEq(token.balanceOf(instance.account), 900_000);

        vm.warp(block.timestamp + 1 days + 1 hours);

        executor.execute(address(instance.account));
        assertEq(token.balanceOf(target), 200_000);
        assertEq(token.balanceOf(instance.account), 800_000);
    }
}
