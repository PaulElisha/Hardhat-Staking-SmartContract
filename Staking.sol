// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IStandardToken} from "./IStandardToken.sol";
import {IrewardToken} from "./IrewardToken.sol";
import {OceanToken} from "./rewardToken.sol";

// allow users to stake standardToken
//able to view the totaltal amount stake by any user
//allows user to be able withdraw their stake amount

contract StakingContract{

    IStandardToken standardToken;

    /// Reward Token Interface
    OceanToken public rewardToken = new OceanToken();

    /// uint256 public rewardRate = 10 / 100 (Dynamic-reward Rate)
    
    uint256 public rewardRate; 

    struct User{
        uint amountStaked;
        uint lastTimeStaked;
        uint256 reward;
    }

    mapping (address => User) user;

    event Staked(uint amountstake, uint totalAmountStaked, uint time);
    // allow users to stake standardToken

    // set the address of the Token to be staked
    constructor(address _standardToken, uint256 _rewardRate){
        standardToken = IStandardToken(_standardToken);
        rewardRate = _rewardRate;
    }

    function stake(uint amount) external {
        uint balance = standardToken.balanceOf(msg.sender);
        require(balance >=  amount, "ERC20 insuficient balance");
        //make external call to standardToken by calling transferfrom;
        bool status = standardToken.transferFrom(msg.sender, address(this), amount);
        require(status == true, "transfer Failed");
        //update state after confirming transfer of standardToken
        User storage _user = user[msg.sender];
        _user.reward += calculateReward();
        _user.amountStaked += amount;
        _user.lastTimeStaked = block.timestamp;
        emit Staked(amount, _user.amountStaked, block.timestamp);
    }

    function getStakeAmount(address who) public view returns(uint _staked){
        User storage _user = user[who];
      _staked = _user.amountStaked;
    }

    function withdraw(uint amount) external{
         uint totalStaked = getStakeAmount(msg.sender);
         require(totalStaked >= amount, "insufficent stake amount");
         User storage _user = user[msg.sender];
         _user.amountStaked -= amount;
         standardToken.transfer(msg.sender, amount);
    }

    function withdrawEther()  external{
        standardToken.withdrawEther();
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function calculateReward() public view returns (uint256) {
        User storage _user = user[msg.sender];
        uint256 stakingDuration = block.timestamp - _user.lastTimeStaked;
        return _user.amountStaked * stakingDuration * rewardRate/100;
    } 

    /// Func to claim reward
    function claimReward() public {
        User storage _user = user[msg.sender];
        uint256 rewardS = _user.reward + calculateReward();
        require(rewardS > 0, "No reward to claim");
        _user.lastTimeStaked = block.timestamp;
        rewardToken.transfer(msg.sender, rewardS);
        rewardS -= _user.reward;
    }

    receive() external payable{}
    fallback() external payable{}


}
