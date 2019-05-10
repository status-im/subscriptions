pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "./math/SafeMath.sol";
import "./math/SafeMath64.sol";
import "./math/SafeMath8.sol";
import "./token/ERC20Token.sol";


interface CompoundContract {
  function  supply (address asset, uint256 amount) external returns (uint256);
  function withdraw (address asset, uint256 requestedAmount) external returns (uint256);
  function getSupplyBalance(address account, address asset) view external returns (uint);
}

/**
 * @title Subscriptions in DAI
 */
contract Subscription {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SafeMath8 for uint8;

    uint128 internal constant ONE = 10 ** 18; // 10^18 is considered 1 in the price feed to allow for decimal calculations
    uint64 internal constant MAX_UINT64 = uint64(-1);
    uint256 internal constant MAX_ACCRUED_VALUE = 2**128;

    ERC20Token public dai;
    address public daiAddress;
    CompoundContract public compound;
    uint256 public totalBalances;
    uint256 constant base = 10 ** 18;
    uint256 constant percentBase = 100 * base;
    uint256 public minDeposit = 12;

    constructor(
        address _compoundAddress,
        address _daiAddress
    )
        public
    {
      dai = ERC20Token(_daiAddress);
      daiAddress = _daiAddress;
      compound = CompoundContract(_compoundAddress);
    }

    event AddAgreement(
        bytes32 agreementId,
        address indexed receiver,
        address indexed payor,
        address token,
        uint256 annualAmount,
        uint256 startDate,
        string indexed description
    );

    event SupplyReceived(
        address account,
        uint256 amount,
        uint256 startingBalance,
        uint256 newBalance,
        uint256 totalBalances
    );

    event WithdrawFunds(
        address receiver,
        uint256 amount,
        bytes32 agreementId
    );

    struct Agreement {
      address receiver;
      address payor;
      address token; // Token to be paid in
      uint256 payRate; // per second in denomination token
      uint256 accruedValue;
      uint256 lastPayment;
      uint256 endDate;
      string description;
      bool terminated;
    }

    mapping(address => uint256) public payorBalances;

    /**
      * @dev map: keccask256(...args) -> Agreement
      */
    mapping(bytes32 => Agreement) agreements;


    /**
     * @notice Do not pay directly into Subscription, please use `supply`.
     */
    function() payable external {
      revert();
    }

    // to get totalInterest subtract totalBalance from compound.supplyBalance
    // divide payRate by totalBalance for percentage
    // multiply percentage by totalInterest to get accumulated interest
    // userBalance = totalBalance + accumulatedInterest

    function percentOf(uint256 percent, uint256 target) internal pure returns (uint256) {
      return target * percent/percentBase;
    }

    function getInterestOwed(uint256 amountOwed) view public returns (uint256) {
      uint256 totalAmount = compound.getSupplyBalance(address(this), daiAddress);
      uint256 totalInterest = totalAmount - totalBalances;
      if (amountOwed == totalBalances) return totalInterest;
      uint256 totalOwned = totalInterest * amountOwed;
      uint256 interestOwed = totalOwned.div(totalBalances);
      return interestOwed;
    }

    function getAnnuityDue(bytes32 agreementId) view public returns (uint256) {
      Agreement memory agreement = agreements[agreementId];
      uint256 lastPayment = agreement.lastPayment;
      uint256 periodic = agreement.payRate;


      // can be generalized getEffectiveRate
      uint256 totalAmount = compound.getSupplyBalance(address(this), daiAddress);
      uint256 totalInterest = totalAmount - totalBalances;

      //effectiveRate may have to be a fraction - totalInterest < totalBalances
      uint256 effectiveRate = totalInterest / totalBalances;

      uint256 periods = now - lastPayment;
      // fraction division
      uint256 periodicRate = effectiveRate / periods;
      // FV annuity due
      uint256 numerator = (1 + periodicRate)**periods - 1;
      uint256 reduced = numerator / periodicRate;
      uint256 annuityDue = (1 + periodicRate) * periodic * reduced;
      return totalInterest;
    }

    function getAmountOwed(bytes32 agreementId) view public returns (uint256) {
      Agreement memory agreement = agreements[agreementId];
      //TODO check for enddate, use instead of now
      return (now.sub(agreement.lastPayment)).mul(agreement.payRate);
    }

    function getTotalOwed(bytes32 agreementId) view public returns (uint256) {
      uint256 amountOwed = getAmountOwed(agreementId);
      uint256 interestOwed = getInterestOwed(amountOwed);
      return interestOwed.add(amountOwed);
    }

    function withdrawFunds(bytes32 agreementId, uint256 amount) public {
      uint256 amountOwed = getAmountOwed(agreementId);
      if (amount == 0 || amountOwed == 0) return;
      require(amount <= amountOwed, "amount can not exceed amount owed");
      Agreement storage agreement = agreements[agreementId];
      uint256 payorBalance = payorBalances[agreement.payor];

      // consider marking subscription terminated in this case
      require(amount <= payorBalance, "amount can not exceed payor balance");

      // withdraw from savings to subscription contract
      compound.withdraw(daiAddress, amount);

      agreement.lastPayment = now;
      dai.transfer(msg.sender, amount);
      payorBalances[agreement.payor] = payorBalance.sub(amount);
      totalBalances = totalBalances.sub(amount);
      emit WithdrawFunds(msg.sender,  amount, agreementId);
    }

    function supply(uint256 amount) public returns (uint256) {
      uint256 balance = payorBalances[msg.sender];
      bool daiTransfer = dai.transferFrom(msg.sender, address(this), amount);
      require(daiTransfer, "Failed to transfer DAI");
      compound.supply(daiAddress, amount);
      uint256 newBalance = balance.add(amount);
      payorBalances[msg.sender] = newBalance;
      totalBalances = totalBalances.add(amount);
      emit SupplyReceived(msg.sender, amount, balance, newBalance, totalBalances);
      return 0;
    }

    function createAgreement(
       address receiver,
       address payor,
       address token,
       uint256 annualAmount,
       uint256 startDate,
       string calldata description
    )
      external
    {
      require(msg.sender == payor, "Agreement must be created by payor");
      require(annualAmount > 0, "AnnualAmount can not be zero");
      bytes32 agreementId = keccak256(abi.encode(receiver, payor, token, annualAmount, startDate, description));
      uint supplyAmount = annualAmount / minDeposit;
      supply(supplyAmount);
      Agreement storage agreement = agreements[agreementId];

      agreement.receiver = receiver;
      agreement.payor = payor;
      agreement.token = token;
      agreement.payRate = annualAmount.div(365.25 days);
      agreement.lastPayment = startDate > 0 ? startDate : now;
      agreement.endDate = MAX_UINT64;
      agreement.description = description;

      emit AddAgreement(
          agreementId,
          receiver,
          payor,
          token,
          annualAmount,
          startDate > 0 ? startDate : now,
          description
     );

    }
}
