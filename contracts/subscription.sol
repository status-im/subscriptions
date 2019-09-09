pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "./math/SafeMath.sol";
import "./math/SafeMath64.sol";
import "./math/SafeMath8.sol";
import "./token/ERC20Token.sol";
import "./math/Exponential.sol";
import "./math/MathQuad.sol";
import { Decimal } from "./math/Decimal.sol";
import { Fraction } from "./math/Fraction.sol";
import { FractionMath } from "./math/FractionMath.sol";
import { Exponent } from "./math/Exponent.sol";

interface CompoundContract {
  function supply (address asset, uint256 amount) external returns (uint256);
  function withdraw (address asset, uint256 requestedAmount) external returns (uint256);
  function getSupplyBalance(address account, address asset) view external returns (uint);
}

/**
 * @title Subscriptions in DAI
*/
contract Subscription is Exponential {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SafeMath8 for uint8;
    using MathQuad for bytes16;

    // ============ Constants ============

    uint256 internal constant MAX_ACCRUED_VALUE = 2**128;

    uint256 constant DEFAULT_PRECOMPUTE_PRECISION = 11;

    uint256 constant DEFAULT_MACLAURIN_PRECISION = 5;

    uint256 constant MAXIMUM_EXPONENT = 80;

    uint128 constant E_TO_MAXIUMUM_EXPONENT = 55406223843935100525711733958316613;
    uint constant E_FIXED = 2718281828459045235;

    uint64 internal constant MAX_UINT64 = uint64(-1);
    bytes16 constant SECONDS_IN_A_YEAR_QUAD = 0x4017e187e00000000000000000000000;
    bytes16 constant ONE = 0x3fff0000000000000000000000000000;

    ERC20Token public dai;
    address public daiAddress;
    CompoundContract public compound;
    uint256 internal totalBalances;
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

    function getAnnuity(bytes32 agreementId) view public returns (uint256) {
      Agreement memory agreement = agreements[agreementId];
      uint256 lastPayment = agreement.lastPayment;
      uint256 periodic = agreement.payRate;

      // can be generalized getEffectiveRate
      uint256 totalAmount = compound.getSupplyBalance(address(this), daiAddress);
      uint256 totalInterest = totalAmount - totalBalances;
      uint256 effectiveRate = Decimal.div(
                                 totalInterest,
                                 Decimal.D256({ value: totalBalances})
                              );
      uint256 periods = now - lastPayment;
      uint256 periodicRate = Decimal.div(
                                effectiveRate,
                                Decimal.D256({ value: periods })
                             );
      uint256 numerator = (1 + periodicRate)**periods - 1;
      uint256 reduced = numerator / periodicRate;
      uint256 annuityDue = (1 + periodicRate) * periodic * reduced;
      return reduced;
    }

    function getAgreement(bytes32 agreementId) view public returns (Agreement memory) {
      return agreements[agreementId];
    }

    function getAnnuityFrac(bytes32 agreementId) view public returns (Fraction.Fraction128 memory) {
      Agreement memory agreement = agreements[agreementId];
      uint256 lastPayment = agreement.lastPayment;
      uint256 periodic = agreement.payRate;

      uint256 totalAmount = compound.getSupplyBalance(address(this), daiAddress);
      uint256 totalInterest = totalAmount - totalBalances;
      uint128 periods = uint128(now - lastPayment);
      // Investigate multiplying effectiveRate and dividing periods by same factor - doesn't work
      // consider https://www.calculatorsoup.com/calculators/financial/future-value-annuity-calculator.php - continous compounding of annuity
      // https://www.calculatorsoup.com/calculators/financial/future-value-calculator.php
      // look into normalizing the number of periods to one, adjusting rate and payments as well
      Fraction.Fraction128 memory effectiveRate = FractionMath.bound(
                                     totalInterest,
                                     totalBalances
                                  );
      Fraction.Fraction128 memory periodicRate = FractionMath.divUint(
                                effectiveRate,
                                periods
                             );
      return effectiveRate;
      Fraction.Fraction128 memory onePlusPeriodic = FractionMath.add(
                                                        Fraction.one(),
                                                        periodicRate
                                                    );
      //return FractionMath.reduceFraction(Fraction.Fraction128({ num: 48, den: 16}));
      //uint128 onePlusNum = onePlusPeriodic.num ** periods;
      //uint128 onePlusDen = onePlusPeriodic.den ** periods;
      //return Fraction.Fraction128({ num: onePlusNum, den: onePlusDen });
      //return Fraction.Fraction128({ num: uint128(1), den: periods });
      Fraction.Fraction128 memory raisedToPeriods = FractionMath.exp(
                                                        onePlusPeriodic,
                                                        periods
                                                    );
      return raisedToPeriods;

      Fraction.Fraction128 memory numerator = FractionMath.sub(
                                                  raisedToPeriods,
                                                  Fraction.one()
                                              );
      Fraction.Fraction128 memory reduced = FractionMath.div(
                                                numerator,
                                                periodicRate
                                            );
      Fraction.Fraction128 memory reducedTimes = FractionMath.mul(
                                                     onePlusPeriodic,
                                                     reduced
                                                 );
      Fraction.Fraction128 memory annuityDue = FractionMath.mul(
                                                  reducedTimes,
                                                  FractionMath.bound(periodic, uint256(1))
                                               );
      return annuityDue;
   }

    function getAnnuityDu(bytes32 agreementId) view public returns (uint256) {
      // V = P/(e^R - 1) * (e^(R*T) - 1) * e^R
      Agreement memory agreement = agreements[agreementId];
      uint128 secondsPerYear = (365 * 1 days);

      uint256 lastPayment = agreement.lastPayment;
      uint256 periodic = agreement.payRate;

      uint256 totalAmount = compound.getSupplyBalance(address(this), daiAddress);
      uint256 totalInterest = (totalAmount - totalBalances) * 10**6;
      uint256 periods = now - lastPayment;
      uint256 interestPerSecond = totalInterest / periods;
      //todo divide by periodic
      uint256 annualizedInterest = interestPerSecond * secondsPerYear;
      uint256 annualRate = annualizedInterest / totalBalances;
      return periods;
      return computeAnnuityDue(periodic, annualRate, periods);
   }

    /**
     * Returns total tokens owed after accruing interest with periodic payments (annuity due). Continuously compounding and accurate to
     * roughly 10^18 decimal places. Annuity due with continuously compounding interest follows the formula:
     * https://www.calculatorsoup.com/calculators/financial/present-value-annuity-calculator.php
     * V = (P/(e^R - 1)) * (1 - 1/e^(R*T)) * e^R
     *
     * @param  periodicPayment     payment to be compounded per second.
     * @param  annualRate          The annualized interest rate.
     * @param  secondsOfInterest   Number of seconds that interest has been accruing
     * @return                     Total amount of tokens owed.
     */
    function computeAnnuityDue(
        uint256 periodicPayment,
        uint256 annualRate,
        uint256 secondsOfInterest
    )
        public
        pure
        returns (uint256)
    {
      //todo remove multiple by secondsOfInterest and divide by earlier
        uint256 numerator = annualRate.mul(secondsOfInterest);
        uint128 denominator = (10**8) * (365 * 1 days);

        // interestRate and secondsOfInterest should both be uint32
        assert(numerator < 2**128);

        // fraction representing (Rate * Time)
        Fraction.Fraction128 memory rt = Fraction.Fraction128({
            num: uint128(numerator),
            den: denominator
        });

        // fraction representing Rate
        Fraction.Fraction128 memory r = Fraction.Fraction128({
          num: uint128(numerator),
              den: denominator
        });


        // calculate e^(RT)
        Fraction.Fraction128 memory eToRT;
        if (numerator.div(denominator) >= MAXIMUM_EXPONENT) {
            // degenerate case: cap calculation
            eToRT = Fraction.Fraction128({
                num: E_TO_MAXIUMUM_EXPONENT,
                den: 1
            });
        } else {
            // normal case: calculate e^(RT)
            eToRT = Exponent.exp(
                rt,
                DEFAULT_PRECOMPUTE_PRECISION,
                DEFAULT_MACLAURIN_PRECISION
            );
        }
        return uint256(eToRT.den);

        // calculate e^R
        Fraction.Fraction128 memory eToR;
        if (annualRate.div(denominator) >= MAXIMUM_EXPONENT) {
          // degenerate case: cap calculation
          eToR = Fraction.Fraction128({
            num: E_TO_MAXIUMUM_EXPONENT,
                den: 1
                });
        } else {
          // normal case: calculate e^R
          eToR = Exponent.exp(
               r,
               DEFAULT_PRECOMPUTE_PRECISION,
               DEFAULT_MACLAURIN_PRECISION
          );
        }

        Fraction.Fraction128 memory eToRTsubOne = FractionMath.sub(
                                                          eToRT,
                                                          Fraction.one()
                                                  );

        Fraction.Fraction128 memory eToRsubOne = FractionMath.sub(
                                                         eToR,
                                                         Fraction.one()
                                                  );

        Fraction.Fraction128 memory quotient = FractionMath.div(
                                                       eToRTsubOne,
                                                       eToRsubOne
                                               );
        uint256 finalNumerator = uint256(quotient.num).mul(periodicPayment);
        /* // e^X for positive X should be greater-than or equal to 1 */
        /* assert(eToRT.num >= eToRT.den); */
        /* assert(eToR.num >= eToR.den); */

        //uint256 annuityDue = FractionMath.safeMultiplyUint256ByFraction(periodicPayment, quotient);
        uint256 annuityDue = finalNumerator.div(uint256(quotient.den));
        return annuityDue;
    }


    function testPower(uint periodic, uint rate, uint elapsedTime)
      public
      pure
      returns (uint)
    {
      (MathError rtErr, uint rateTime) = mulUInt(rate, elapsedTime);
      (MathError eToRTerr, uint eToRT) = expC(rateTime);
      (MathError eToRerr, uint eToR) = expC(rate);
      uint reduced = (eToRT - 1) / (eToR - 1);
      //TODO safe math checks
      return periodic * reduced;
    }

    /* function getAnnuityDue64(int128 periodicPayment, int128 rate, int128 elapsedTime) */
    /*   public */
    /*   pure */
    /*   returns (uint64) */
    /* { */
    /*   //int128 periodicBytes = annualSalary.fromUInt().div(SECONDS_IN_A_YEAR_64); */
    /*   // int128 rateBytes = rate.fromUInt(); */
    /*   //int128 ratePct = rateBytes.div(HUNDRED.fromUInt()); */
    /*   //int128 ratePerSecond = ratePct.div(SECONDS_IN_A_YEAR_64); */
    /*   //int128 elapsedBytes = elapsedTime.fromUInt(); */
    /*   int128 rateTime = rate.mul(elapsedTime); */
    /*   int128 eToRT = rateTime.exp(); */
    /*   int128 eToR = rate.exp(); */
    /*   int128 reduced = eToRT.sub(ONE).div(eToR.sub(ONE)); */
    /*   int128 result = periodicPayment.mul(reduced); */
    /*   return result.toUInt(); */
    /* } */

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
