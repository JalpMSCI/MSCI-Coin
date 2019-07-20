pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";
import "./Pausable.sol";
/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract SimpleToken is ERC20, ERC20Detailed, Ownable, Pausable {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("SimpleToken", "SIM", 18) {
        _mint(msg.sender, 10000 * (10 ** uint256(decimals())));
    }
}
