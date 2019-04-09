pragma solidity ^0.5.3;

contract Compound {
  function  supply (address asset, uint256 amount) external returns (uint256);
  function withdraw (address asset, uint256 requestedAmount) external returns (uint256);
  // return supply balance with any accumulated interest for `asset` belonging to `account`
  function getSupplyBalance(address account, address asset) view external returns (uint);
}
