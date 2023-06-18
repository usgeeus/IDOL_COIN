// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockFailedMintDSC is ERC20Burnable, Ownable {
    error IDOLFundCoin__AmountMustBeMoreThanZero();
    error IDOLFundCoin__BurnAmountExceedsBalance();
    error IDOLFundCoin__NotZeroAddress();

    constructor() ERC20("IDOLFundCoin", "DSC") {}

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
        return false;
    }
}
