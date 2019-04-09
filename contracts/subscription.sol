pragma solidity ^0.5.3;

import "./math/SafeMath.sol";
import "./math/SafeMath64.sol";
import "./math/SafeMath8.sol";


interface CompoundContract {
  function  supply (address asset, uint256 amount) external returns (uint256);
  function withdraw (address asset, uint256 requestedAmount) external returns (uint256);
  // return supply balance with any accumulated interest for `asset` belonging to `account`
  function getSupplyBalance(address account, address asset) view external returns (uint);
}

/**
 * @title Payroll in multiple currencies
 */
contract Subscription {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SafeMath8 for uint8;

    address compoundAddress = 0x3FDA67f7583380E67ef93072294a7fAc882FD7E7;
    address daiAddress = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    CompoundContract compound = CompoundContract(compoundAddress);

    event AddAgreement(
        bytes32 agreementId,
        address indexed receiver,
        address indexed payor,
        address token,
        uint256 annualAmount,
        uint256 startDate,
        string indexed description
    );

    // Employees start at index 1, to allow us to use employees[0] to check for non-existent address
    // mappings with employeeIds
    uint256 public nextAgreement;

    struct Receiver {
      address accountAddress; // unique, but can be changed over time
      mapping(address => uint8) allocation;
    }

    struct Payor {
      address accountAddress;
      mapping(address => uint256) balances;
    }

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

    /**
     * @dev Container for customer balance information written to storage.
     *
     *      struct Balance {
     *        principal = customer total balance with accrued interest after applying the customer's most recent balance-changing action
     *        interestIndex = the total interestIndex as calculated after applying the customer's most recent balance-changing action
     *      }
     */
    struct Balance {
      uint principal;
      uint interestIndex;
    }

    /**
     * @dev 2-level map: customerAddress -> assetAddress -> balance for payors
     */
    mapping(address => mapping(address => Balance)) public payorBalances;


    /**
     * @dev 2-level map: customerAddress -> assetAddress -> balance for receivers
     */
    mapping(address => mapping(address => Balance)) public receiverBalances;

    /**
      * @dev map: keccask256(...args) -> Agreement
      */
    mapping(bytes32 => Agreement) agreements;

    constructor() public {
      nextAgreement = 1;
    }

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

    function getAmountOwed(bytes32 agreementId) view public returns (uint256) {
      Agreement memory agreement = agreements[agreementId];
      return (now - agreement.lastPayment) * agreement.payRate;
    }

    function withdrawFunds(address recipient, bytes32 agreementId) public {
      // How much are you owed right now?
      uint amount = getAmountOwed(agreementId);
      if (amount == 0) return;

      // Take it out from savings
      compound.withdraw(daiAddress, amount);

      // Pay it out
      agreements[agreementId].lastPayment = now;
      //dai.transfer(recipient, amount);
      //emit MemberPaid( recipient,  amount, justification);
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
      bytes32 agreementId = keccak256(abi.encode(receiver, payor, token, annualAmount, startDate, description));
      Agreement storage agreement = agreements[agreementId];

      agreement.receiver = receiver;
      agreement.payor = payor;
      agreement.token = token;
      agreement.payRate = annualAmount / 325.25 days;
      agreement.lastPayment = startDate > 0 ? startDate : now;
      agreement.endDate = MAX_UINT64;
      agreement.description = description;

      // TODO should be payor -> receiver mapping

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
