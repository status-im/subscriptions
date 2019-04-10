pragma solidity ^0.5.3;
import "../token/ERC20Token.sol";



// Contract to mock interactions with Compound.finance

contract Compound {
  uint256 constant base = 10 ** 18;
  uint256 constant percentBase = 100 * base;
  uint256 constant interestRate = 4 * base; // 4%
  uint256 constant periodicRate = interestRate / (365.25 days);
  constructor() public {}

  /**
   * @dev 2-level map: customerAddress -> balance
   */
  mapping(address => uint) public supplyBalances;
  mapping(address => uint) public supplyTimes;


  function supply(address asset, uint amount) public returns (uint) {
    uint balance = supplyBalances[msg.sender];
    ERC20Token(asset).transferFrom(msg.sender, address(this), amount);
    supplyBalances[msg.sender] = balance + amount;
    supplyTimes[msg.sender] = now;
    return 0;
  }

  function withdraw(address asset, uint requestedAmount) public returns (uint) {
    return 0;
  }

  function getSupplyBalance(address account, address asset) view public returns (uint) {
    uint supplyTime = supplyTimes[msg.sender];
    uint balance = supplyBalances[msg.sender];
    uint timeDelta = now - supplyTime;
    uint accruedInterest = timeDelta * periodicRate;
    return accruedInterest + balance;
  }
}
