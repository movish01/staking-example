// SPDX-License-Identifier: unlicensed

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// custom errors
error Staking__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking {
    //allowing only a single token, if we want to apply multiple token then we have to keep track of prices of all tokens in respect to one another

    IERC20 public s_tokenStaked; // s_ tells that variable is storage variable
    IERC20 public s_rewardToken;

    // mapping address to how much they staked
    mapping(address => uint256) public s_balances;

    //mapping how much user has been paid
    mapping(address => uint256) public s_userPaidReward;

    // mapping how much reward each user has
    mapping (address => uint256) public s_rewards;

    // how many tokens send to this contract
    uint256 public s_totalSupply;
    uint256 public s_rewardTokenStored;
    uint256 public constant REWARD_RATE = 100;
    uint public s_lastUpdateTime;

    modifier updateReward(address account) {
        s_rewardTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userPaidReward[account] = s_rewardTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if(amount == 0){
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }

    constructor(address tokenStaked, address rewardToken) {
        s_tokenStaked = IERC20(tokenStaked);
        s_rewardToken = IERC20(rewardToken);
    }

    function earned(address account) public view returns(uint256) {
        uint256 currentBalance = s_balances[account];
        
        //how much they have been paid already
        uint256 amountPaid =  s_userPaidReward[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];

        uint256 _earned = (currentBalance * (currentRewardPerToken - amountPaid)/1e18) + pastRewards;
        return _earned;
    }

    function rewardPerToken() public view returns (uint256) {
        if(s_totalSupply == 0){
            return s_rewardTokenStored;
        }    
        return s_rewardTokenStored + (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) / s_totalSupply);
    }

    function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount){
        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply = s_totalSupply + amount;

        bool success = s_tokenStaked.transferFrom(
            msg.sender,
            address(this),
            amount
        );

        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) moreThanZero(amount){
        s_balances[msg.sender] = s_balances[msg.sender] - amount;
        s_totalSupply = s_totalSupply - amount;

        bool success = s_tokenStaked.transfer(msg.sender, amount);

        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function getReward() external updateReward(msg.sender){
        uint256 reward = s_rewards[msg.sender];

        bool success = s_rewardToken.transfer(msg.sender, reward);

        if(!success) {
            revert Staking__TransferFailed();
        }
    }
}
