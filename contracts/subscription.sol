pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "./math/SafeMath.sol";
import "./math/SafeMath64.sol";
import "./math/SafeMath8.sol";
import "./token/ERC20Token.sol";
import "./math/MathQuad.sol";

interface CompoundContract {
  function supply (address asset, uint256 amount) external returns (uint256);
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
    using MathQuad for bytes16;

    ERC20Token public dai;
    CompoundContract public compound;

    // ============ Constants ============

    uint64 internal constant MAX_UINT64 = uint64(-1);
    bytes16 internal constant SECONDS_IN_A_YEAR_QUAD = 0x4017e187e00000000000000000000000;
    bytes16 internal constant ONE = 0x3fff0000000000000000000000000000;

    address public daiAddress;
    uint256 internal totalBalances;
    uint256 public minDepositRatio = 12;


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

    function getInterestOwed(uint256 amountOwed) view public returns (uint256) {
      uint256 totalAmount = compound.getSupplyBalance(address(this), daiAddress);
      uint256 totalInterest = totalAmount - totalBalances;
      if (amountOwed == totalBalances) return totalInterest;
      uint256 totalOwned = totalInterest * amountOwed;
      uint256 interestOwed = totalOwned.div(totalBalances);
      return interestOwed;
   }

    function getOwedPayee(bytes32 agreementId)
      view
      public
      returns (int256)
    {
      Agreement memory agreement = agreements[agreementId];
      uint256 lastPayment = agreement.lastPayment;
      uint256 periodic = agreement.payRate;
      uint256 totalAmount = compound.getSupplyBalance(address(this), daiAddress);
      uint256 totalInterest = totalAmount - totalBalances;
      uint256 periods = now - lastPayment;
      bytes16 periodicRate = computePeriodicRate(totalInterest, periods);
      return getAnnuityDueQuad(periodic.toBytes(), periodicRate, periods.toBytes());
    }

    function getAnnuityDueQuad(bytes16 periodicPayment, bytes16 rate, bytes16 elapsedTime)
      public
      pure
      returns (int256)
    {
      bytes16 rateTime = rate.mul(elapsedTime);
      bytes16 eToRT = rateTime.exp();
      bytes16 eToR = rate.exp();
      bytes16 reduced = eToRT.sub(ONE).div(eToR.sub(ONE));
      bytes16 result = periodicPayment.mul(reduced);
      return result.toInt();
    }

    function getAnnuityDueWrapper(uint periodicPayment, uint rate, uint elapsedTime)
      public
      pure
      returns (int256)
    {
      uint base = 100;
      bytes16 interestRate = rate.toBytes().div(base.toBytes());
      return getAnnuityDueQuad(periodicPayment.toBytes(), interestRate, elapsedTime.toBytes());
    }

    function computePeriodicRate(uint totalInterest, uint elapsedTime)
      public
      view
      returns (bytes16)
    {
      bytes16 interest = totalInterest.toBytes();
      bytes16 balance = totalBalances.toBytes();
      bytes16 periods = elapsedTime.toBytes();
      bytes16 effectiveRate = interest.div(balance);
      return effectiveRate.div(periods);
    }

    function getAgreement(bytes32 agreementId) view public returns (Agreement memory) {
      return agreements[agreementId];
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
      uint supplyAmount = annualAmount / minDepositRatio;
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
