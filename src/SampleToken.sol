// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SampleToken is ERC20 {
    address public bridge;

    constructor(string memory _name, string memory _symbol, uint256 _amount, address _bridge) ERC20(_name, _symbol) {
        bridge = _bridge;
        _mint(msg.sender, _amount);
    }

    modifier onlyBridge() {
        require(msg.sender == bridge, "Token: caller is not the bridge");
        _;
    }

    function mint(address _to, uint256 _amount) external onlyBridge {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyBridge {
        _burn(_from, _amount);
    }
}
