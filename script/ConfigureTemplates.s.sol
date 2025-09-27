// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Vesting721Of721Plus.sol";

/**
 * @title ConfigureTemplatesScript
 * @dev Configure linear vesting templates
 */
contract ConfigureTemplatesScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get contract address from environment or use default
        address vestingAddress = vm.envOr("VESTING_ADDRESS", address(0));
        require(vestingAddress != address(0), "VESTING_ADDRESS not set");
        
        Vesting721Of721Plus vesting = Vesting721Of721Plus(vestingAddress);
        
        console.log("Configuring templates for contract:", vestingAddress);
        console.log("Account:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Template 1: 3 month cliff, 12 month duration, 1 day slice
        uint256 template1 = vesting.setLinearTemplate(
            90 days,    // 3 months cliff
            365 days,   // 12 months duration
            1 days      // 1 day slice
        );
        console.log("Template 1 (3m cliff, 12m duration, 1d slice) created with ID:", template1);

        // Template 2: No cliff, 6 month duration, 1 week slice
        uint256 template2 = vesting.setLinearTemplate(
            0,          // No cliff
            180 days,   // 6 months duration
            7 days      // 1 week slice
        );
        console.log("Template 2 (0 cliff, 6m duration, 1w slice) created with ID:", template2);

        // Template 3: 1 month cliff, 24 month duration, 1 day slice
        uint256 template3 = vesting.setLinearTemplate(
            30 days,    // 1 month cliff
            730 days,   // 24 months duration
            1 days      // 1 day slice
        );
        console.log("Template 3 (1m cliff, 24m duration, 1d slice) created with ID:", template3);

        // Template 4: No cliff, 1 year duration, no slice (continuous)
        uint256 template4 = vesting.setLinearTemplate(
            0,          // No cliff
            365 days,   // 1 year duration
            0           // No slice (continuous)
        );
        console.log("Template 4 (0 cliff, 1y duration, continuous) created with ID:", template4);

        vm.stopBroadcast();

        console.log("All templates configured successfully!");
    }
}
