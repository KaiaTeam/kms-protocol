// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title USDTMock
 * @dev Mock USDT token for testing purposes
 * USDT has 6 decimal places unlike most ERC20 tokens which have 18
 */
contract USDTMock is ERC20, Ownable {
    uint8 private constant _DECIMALS = 6;
    
    constructor() ERC20("Tether USD", "USDT") Ownable(msg.sender) {}
    
    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }
    
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
    
    // Helper function to convert from USDT units to human readable amounts
    function toUSDT(uint256 humanAmount) public pure returns (uint256) {
        return humanAmount * 10**_DECIMALS;
    }
    
    // Helper function to convert from USDT units to human readable amounts
    function fromUSDT(uint256 tokenAmount) public pure returns (uint256) {
        return tokenAmount / 10**_DECIMALS;
    }
}