// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingPool is ReentrancyGuard, Ownable {
    IERC20 public stakingToken;
    
    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 lastRewardTimestamp;
    }
    
    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;
    uint256 public rewardRate = 100; // 100 tokens per day per 1000 tokens staked
    uint256 public rewardPool;
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardPoolFunded(uint256 amount);
    
    constructor(address _stakingToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
    }
    
    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        
        // Transfer tokens from user to contract
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        // Update stake info
        StakeInfo storage stakeInfo = stakes[msg.sender];
        if (stakeInfo.amount > 0) {
            // If user already has a stake, claim rewards first
            _claimRewards();
        } else {
            stakeInfo.lastRewardTimestamp = block.timestamp;
        }
        
        stakeInfo.amount += _amount;
        stakeInfo.timestamp = block.timestamp;
        totalStaked += _amount;
        
        emit Staked(msg.sender, _amount);
    }
    
    function unstake(uint256 _amount) external nonReentrant {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount >= _amount, "Insufficient stake");
        
        // Claim rewards before unstaking
        _claimRewards();
        
        stakeInfo.amount -= _amount;
        totalStaked -= _amount;
        
        // Transfer tokens back to user
        require(stakingToken.transfer(msg.sender, _amount), "Transfer failed");
        
        emit Unstaked(msg.sender, _amount);
    }
    
    function claimRewards() external nonReentrant {
        _claimRewards();
    }
    
    function _claimRewards() internal {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        if (stakeInfo.amount == 0) return;
        
        uint256 reward = calculateReward(msg.sender);
        if (reward > 0) {
            require(reward <= rewardPool, "Insufficient reward pool");
            rewardPool -= reward;
            stakeInfo.lastRewardTimestamp = block.timestamp;
            
            require(stakingToken.transfer(msg.sender, reward), "Transfer failed");
            emit RewardClaimed(msg.sender, reward);
        }
    }
    
    function calculateReward(address _user) public view returns (uint256) {
        StakeInfo storage stakeInfo = stakes[_user];
        if (stakeInfo.amount == 0) return 0;
        
        uint256 timeStaked = block.timestamp - stakeInfo.lastRewardTimestamp;
        return (stakeInfo.amount * rewardRate * timeStaked) / (1000 * 1 days);
    }
    
    function fundRewardPool(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        rewardPool += _amount;
        emit RewardPoolFunded(_amount);
    }
    
    function setRewardRate(uint256 _newRate) external onlyOwner {
        rewardRate = _newRate;
    }
} 