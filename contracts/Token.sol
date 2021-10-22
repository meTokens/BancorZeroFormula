// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Token
contract Token is ERC20Burnable, Ownable {
    string public version;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        version = "0.2";
    }

    function mint(address to, uint256 amount) onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 value) onlyOwner {
        _burn(from, value);
    }
}