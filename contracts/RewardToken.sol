//SPDX-License-Identifier: unlicencsed

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    constructor() ERC20 ("RewardToken", "RWT") {
        _mint(msg.sender, 100000 * 10**18);
    }
}