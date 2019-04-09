pragma solidity ^0.5.3;
import "../token/ERC20Token.sol";



// Contract to mock interactions with Compound.finance

contract Compound {
  constructor() public {}

  /**
   * @dev 2-level map: customerAddress -> balance
   */
  mapping(address => uint) public supplyBalances;


  function supply(address asset, uint amount) public returns (uint) {
    uint balance = supplyBalances[msg.sender];
    ERC20Token(asset).transferFrom(msg.sender, address(this), amount);
    supplyBalances[msg.sender] = balance + amount;
    return 0;
  }

  function withdraw(address asset, uint requestedAmount) public returns (uint) {
    return 0;
  }

  function getSupplyBalance(address account, address asset) view public returns (uint) {
    return 0;
  }
}
