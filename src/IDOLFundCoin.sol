// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity 0.8.19;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title IDOLFundCoin
 * @author Patrick Collins
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USD)
 * Collateral Type: Crypto
 *
 * This is the contract meant to be owned by IFCEngine. It is a ERC20 token that can be minted and burned by the IFCEngine smart contract.
 */
contract IDOLFundCoin is ERC20Burnable, Ownable {
    error IDOLFundCoin__AmountMustBeMoreThanZero();
    error IDOLFundCoin__BurnAmountExceedsBalance();
    error IDOLFundCoin__NotZeroAddress();

    constructor() ERC20("IDOLFundCoin", "IDOL") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert IDOLFundCoin__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert IDOLFundCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert IDOLFundCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert IDOLFundCoin__AmountMustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
