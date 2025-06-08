# Staking Pool Smart Contract

A secure and efficient ERC20 token staking pool that allows users to earn rewards for staking their tokens.

## Overview

The StakingPool contract enables users to:
- Stake ERC20 tokens
- Earn rewards based on staking duration
- Unstake tokens at any time
- Claim accumulated rewards

The contract includes security features like reentrancy protection and proper access control.

## Features

- **Token Staking**: Users can stake any ERC20 token
- **Reward System**: Rewards accumulate based on staking duration
- **Admin Controls**: Contract owner can fund the reward pool and adjust reward rates
- **Security**: Protected against reentrancy attacks
- **Events**: Comprehensive event logging for all major actions

## Technical Details

### Contract Architecture

The contract inherits from:
- `ReentrancyGuard`: Prevents reentrancy attacks
- `Ownable`: Provides basic authorization control

### Key Components

1. **StakeInfo Struct**
```solidity
struct StakeInfo {
    uint256 amount;           // Amount of tokens staked
    uint256 timestamp;        // When the stake was made
    uint256 lastRewardTimestamp; // Last time rewards were claimed
}
```

2. **State Variables**
- `stakingToken`: The ERC20 token being staked
- `totalStaked`: Total amount of tokens staked
- `rewardRate`: Reward rate (tokens per day per 1000 tokens)
- `rewardPool`: Available rewards for distribution

### Main Functions

#### User Functions
- `stake(uint256 _amount)`: Stake tokens
- `unstake(uint256 _amount)`: Unstake tokens
- `claimRewards()`: Claim accumulated rewards

#### Admin Functions
- `fundRewardPool(uint256 _amount)`: Fund the reward pool
- `setRewardRate(uint256 _newRate)`: Update reward rate

### Events
- `Staked(address indexed user, uint256 amount)`
- `Unstaked(address indexed user, uint256 amount)`
- `RewardClaimed(address indexed user, uint256 amount)`
- `RewardPoolFunded(uint256 amount)`

## Reward Calculation

Rewards are calculated using the formula:
```
reward = (stakedAmount * rewardRate * timeStaked) / (1000 * 1 days)
```

Where:
- `stakedAmount`: Amount of tokens staked
- `rewardRate`: Current reward rate
- `timeStaked`: Time since last reward claim

## Security Features

1. **Reentrancy Protection**
   - All external functions are protected with `nonReentrant` modifier
   - Prevents reentrancy attacks during token transfers

2. **Access Control**
   - Admin functions restricted to contract owner
   - User functions accessible to all

3. **Input Validation**
   - Amount checks
   - Balance checks
   - Transfer validations

## Testing

The contract includes comprehensive tests using Foundry:

1. **Basic Operations**
   - Staking
   - Unstaking
   - Reward claiming

2. **Edge Cases**
   - Insufficient stake
   - Multiple stakes
   - Reward calculations

To run tests:
```bash
forge test
```

## Deployment

1. Deploy an ERC20 token contract
2. Deploy the StakingPool contract with the token address
3. Fund the reward pool with tokens
4. Set the initial reward rate

## Usage Example

```solidity
// Approve tokens
token.approve(stakingPoolAddress, amount);

// Stake tokens
stakingPool.stake(amount);

// Claim rewards
stakingPool.claimRewards();

// Unstake tokens
stakingPool.unstake(amount);
```

## Best Practices

1. Always check token approvals before staking
2. Monitor reward pool balance
3. Consider gas costs for frequent operations
4. Keep track of reward rates

## License

MIT License 