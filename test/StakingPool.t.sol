// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/StakingPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
}

contract StakingPoolTest is Test {
    StakingPool public stakingPool;
    MockToken public token;
    address public alice = address(1);
    address public bob = address(2);
    
    function setUp() public {
        token = new MockToken();
        stakingPool = new StakingPool(address(token));
        
        // Transfer tokens to test users
        token.transfer(alice, 1000 * 10**token.decimals());
        token.transfer(bob, 1000 * 10**token.decimals());
        
        // Fund reward pool
        token.approve(address(stakingPool), type(uint256).max);
        stakingPool.fundRewardPool(10000 * 10**token.decimals());
    }
    
    function testStake() public {
        vm.startPrank(alice);
        token.approve(address(stakingPool), 100 * 10**token.decimals());
        stakingPool.stake(100 * 10**token.decimals());
        
        (uint256 amount, , ) = stakingPool.stakes(alice);
        assertEq(amount, 100 * 10**token.decimals());
        assertEq(stakingPool.totalStaked(), 100 * 10**token.decimals());
        vm.stopPrank();
    }
    
    function testUnstake() public {
        // First stake
        vm.startPrank(alice);
        token.approve(address(stakingPool), 100 * 10**token.decimals());
        stakingPool.stake(100 * 10**token.decimals());
        
        // Then unstake
        stakingPool.unstake(50 * 10**token.decimals());
        
        (uint256 amount, , ) = stakingPool.stakes(alice);
        assertEq(amount, 50 * 10**token.decimals());
        assertEq(stakingPool.totalStaked(), 50 * 10**token.decimals());
        vm.stopPrank();
    }
    
    function testRewards() public {
        vm.startPrank(alice);
        token.approve(address(stakingPool), 1000 * 10**token.decimals());
        stakingPool.stake(1000 * 10**token.decimals());
        
        // Move forward 1 day
        vm.warp(block.timestamp + 1 days);
        
        // Claim rewards
        stakingPool.claimRewards();
        
        // Should have earned 100 tokens (100 tokens per day per 1000 tokens staked)
        assertEq(token.balanceOf(alice), 100 * 10**token.decimals());
        vm.stopPrank();
    }
    
    function testMultipleStakes() public {
        vm.startPrank(alice);
        token.approve(address(stakingPool), 1000 * 10**token.decimals());
        
        // First stake
        stakingPool.stake(500 * 10**token.decimals());
        
        // Move forward 1 day
        vm.warp(block.timestamp + 1 days);
        
        // Second stake
        stakingPool.stake(500 * 10**token.decimals());
        
        // Move forward another day
        vm.warp(block.timestamp + 1 days);
        
        // Claim rewards
        stakingPool.claimRewards();
        
        // Should have earned rewards for both stakes
        assertEq(token.balanceOf(alice), 150 * 10**token.decimals());
        vm.stopPrank();
    }
    
    function test_RevertWhen_InsufficientStake() public {
        vm.startPrank(alice);
        token.approve(address(stakingPool), 100 * 10**token.decimals());
        stakingPool.stake(100 * 10**token.decimals());

        // Verify staked amount
        (uint256 amount, , ) = stakingPool.stakes(alice);
        assertEq(amount, 100 * 10**token.decimals(), "Staked amount should be 100 tokens");
        assertEq(stakingPool.totalStaked(), 100 * 10**token.decimals(), "Total staked should be 100 tokens");

        // Try to unstake more than staked - should fail
        bool success = true;
        try stakingPool.unstake(200 * 10**token.decimals()) {
            success = false;
        } catch {
            // Expected to fail
        }
        assertTrue(success, "Unstaking more than staked amount should fail");

        // Verify staked amount hasn't changed
        (amount, , ) = stakingPool.stakes(alice);
        assertEq(amount, 100 * 10**token.decimals(), "Staked amount should still be 100 tokens");
        assertEq(stakingPool.totalStaked(), 100 * 10**token.decimals(), "Total staked should still be 100 tokens");
        
        vm.stopPrank();
    }
} 