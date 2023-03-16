// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Staking {
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

    function approveTokens() external {
        myBalance = axToken.balanceOf(msg.sender);
        approveAmount = entryFeeAmount * 1e18;
        bool allowedAX = axToken.approve(msg.sender, approveAmount);
        require(allowedAX, "Failed to approve AX Tokens");
    }

    function joinLeague() external {
        require(block.timestamp >= leagueStartTime, "League has not started yet");
        require(block.timestamp <= leagueEndTime, "League has already ended");

        uint256 allowance = axToken.allowance(msg.sender, address(this));
        require(allowance < entryFeeAmount, "Insufficient AX token allowance");

        bool success = axToken.transferFrom(msg.sender, address(this), entryFeeAmount);
        require(success, "Failed to transfer AX tokens");
        require(myBalance < entryFeeAmount, "Insufficient AX token balance");

        stakedAmounts[msg.sender] += entryFeeAmount;
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