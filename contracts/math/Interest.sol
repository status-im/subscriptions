pragma solidity ^0.5.3;

import "./SafeMath.sol";

/**
 * @title Interest
 * @dev Math operations used in financial calculations
 */
library Interest {
    using SafeMath for uint256;
    uint256 constant base = 10 * 10 ** 18;

    function percentOf(uint256 percent, uint256 target) internal pure returns (uint256) {
      return target.mul(percent.div(base));
   }
}
