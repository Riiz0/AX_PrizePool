// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract PrizePool {
    IERC20 public axToken;
    address public admin;
    uint256 public entryFeeAmount;
    uint256 public leagueStartTime;
    uint256 public leagueEndTime;
    uint256 public approveAmount;
    uint256 public myBalance;
    mapping(address => uint256) public stakedAmounts;

    constructor(address _axToken, uint256 _entryFeeAmount, uint256 _leagueStartTime, uint256 _leagueEndTime) {
        axToken = IERC20(_axToken);
        admin = msg.sender;
        entryFeeAmount = _entryFeeAmount * 1e18;
        leagueStartTime = _leagueStartTime;
        leagueEndTime = _leagueEndTime;
    }

    function joinLeague() external {
        //require(block.timestamp < leagueStartTime, "Grace Period");
        require(block.timestamp <= leagueEndTime, "League has already ended");
        uint256 allowance = axToken.allowance(msg.sender, address(this));
        approveAmount = allowance;
        myBalance = axToken.balanceOf(msg.sender);
        require(allowance >= entryFeeAmount, "Insufficient AX token allowance");

        bool success = axToken.transferFrom(msg.sender, address(this), entryFeeAmount);
        require(success, "Failed to transfer AX tokens");
        //require(myBalance >= entryFeeAmount, "Insufficient AX token balance");

        stakedAmounts[msg.sender] += entryFeeAmount;
    }

    function withdrawBeforeLeagueStarts() external {
        require(block.timestamp < leagueStartTime, "Grace period has ended");
        uint256 stakedAmount = stakedAmounts[msg.sender];
        require(stakedAmount > 0, "No staked amount to withdraw");
        stakedAmounts[msg.sender] = 0;
        bool success = axToken.transfer(msg.sender, stakedAmount);
        require(success, "Failed to transfer AX tokens");
    }

    function distributePrize(address winner) external {
        require(msg.sender == admin, "Only admin can distribute prize");
        require(block.timestamp >= leagueEndTime, "League has not ended yet");

        uint256 totalStakedAmount = axToken.balanceOf(address(this));
        uint256 winnerStakedAmount = stakedAmounts[winner];

        require(winnerStakedAmount > 0, "Winner has no staked amount");
        require(totalStakedAmount >= winnerStakedAmount, "Not enough AX tokens to distribute");

        bool success = payable(winner).send(winnerStakedAmount);
        require(success, "Failed to transfer AX tokens to winner");
    }
}