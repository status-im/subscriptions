pragma solidity ^0.5.3;


// Contract to mock interactions with Compound.finance

contract Compound {
  constructor() public {}
  function supply(address asset, uint amount) public returns (uint) {
    return 0;
  }

  function withdraw(address asset, uint requestedAmount) public returns (uint) {
    return 0;
  }

  function getSupplyBalance(address account, address asset) view public returns (uint) {
    return 0;
  }
}
