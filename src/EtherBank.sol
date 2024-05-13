// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

contract EtherBank {
    using PriceConverter for uint256;

    error EtherBank__NotEnoughEthSend(string message);
    error EtherBank__WithdrawInsufficientBalance(string message);
    error EtherBank__WithdrawAmount(string message);
    error EtherBank__SelfAccountTransfer(string message);
    error EtherBank__InvalidRecipientAddress(string message);
    error EtherBank__TransferInsufficientBalance(string message);
    error EtherBank__TransferAmount(string message);
    error EtherBank__FailedToSendEth();
    error EtherBank__NoReentrant();
    error EtherBank__OnlyDepositors(string message);

    address payable private immutable i_owner;
    uint256 public constant MINIMUM_USD_DEPOSIT = 100 * 10 ** 18;
    mapping(address => uint256) private s_balances;
    AggregatorV3Interface private s_priceFeed;
    address payable[] private s_users;
    bool private locked;

    modifier nonReentrancy() {
        // require(!locked, "No Re-entrant");
        // locked = true;
        // _;
        // locked = false;
        if (!locked) {
            locked = true;
            _;
            locked = false;
        } else {
            revert EtherBank__NoReentrant();
        }
    }

    constructor(address priceFeed) {
        i_owner = payable(msg.sender);
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function deposit() external payable {
        //require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Minimum deposit amount is 100 USD");
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD_DEPOSIT) {
            revert EtherBank__NotEnoughEthSend("Minimum deposit amount is 100 USD");
        }
        s_balances[msg.sender] += msg.value;
        s_users.push(payable(msg.sender));
    }

    function withdraw(uint256 _amount) external nonReentrancy {
        // Check
        //require(s_balances[msg.sender] >= _amount, "Insufficient balance");
        if (s_balances[msg.sender] < _amount) {
            revert EtherBank__WithdrawInsufficientBalance("Insufficient balance to withdraw");
        }

        //require(_amount > 0, "Withdraw amount must be greater than zero");
        if (_amount <= 0) {
            revert EtherBank__WithdrawAmount("Withdraw amount must be greater than zero");
        }

        // Effect
        s_balances[msg.sender] -= _amount;

        // Interaction
        (bool sent,) = payable(msg.sender).call{value: _amount}("");
        //require(sent, "Failed to send ETH");
        if (!sent) {
            revert EtherBank__FailedToSendEth();
        }
    }

    function transfer(address payable _recipient, uint256 _amount) external {
        //require(msg.sender != _recipient, "Can't transfer self account");
        if (msg.sender == _recipient) {
            revert EtherBank__SelfAccountTransfer("Can't transfer self account");
        }

        //require(s_balances[msg.sender] >= _amount, "Insufficient balance");
        if (s_balances[msg.sender] < _amount) {
            revert EtherBank__TransferInsufficientBalance("Insufficient balance to transfer");
        }

        //require(_to != address(0), "Invalid recipient address");
        if (_recipient == address(0)) {
            revert EtherBank__InvalidRecipientAddress("Ivalid recipient address");
        }

        //require(_amount > 0, "Transfer amount must be greater than zero");
        if (_amount <= 0) {
            revert EtherBank__TransferAmount("Transfer amount must be greater than zero");
        }

        s_balances[msg.sender] -= _amount;
        s_balances[_recipient] += _amount;
    }

    // Getter Functions

    /// @return The balance of EtherBank contract
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @return The balance of user
    function getAccountBalance(address _account) external view returns (uint256) {
        return s_balances[_account];
    }

    /// @return The user address
    function getUserAddress(uint256 _index) external view returns (address) {
        return s_users[_index];
    }

    /// @return The owner address
    function getOwnerAddress() external view returns (address) {
        return i_owner;
    }

    /// @return Price feed
    function getPriceFeed() external view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    /// @return Price feed version
    function getVersion() external view returns (uint256) {
        return s_priceFeed.version();
    }
}
