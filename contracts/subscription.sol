pragma solidity ^0.5.3;

import "./math/SafeMath.sol";
import "./math/SafeMath64.sol";
import "./math/SafeMath8.sol";


/**
 * @title Payroll in multiple currencies
 */
contract Subscription {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SafeMath8 for uint8;

    bytes32 constant public ADD_EMPLOYEE_ROLE = keccak256("ADD_EMPLOYEE_ROLE");
    bytes32 constant public TERMINATE_EMPLOYEE_ROLE = keccak256("TERMINATE_EMPLOYEE_ROLE");
    bytes32 constant public SET_EMPLOYEE_SALARY_ROLE = keccak256("SET_EMPLOYEE_SALARY_ROLE");
    bytes32 constant public ADD_ACCRUED_VALUE_ROLE = keccak256("ADD_ACCRUED_VALUE_ROLE");
    bytes32 constant public ALLOWED_TOKENS_MANAGER_ROLE = keccak256("ALLOWED_TOKENS_MANAGER_ROLE");
    bytes32 constant public CHANGE_PRICE_FEED_ROLE = keccak256("CHANGE_PRICE_FEED_ROLE");
    bytes32 constant public MODIFY_RATE_EXPIRY_ROLE = keccak256("MODIFY_RATE_EXPIRY_ROLE");

    uint128 internal constant ONE = 10 ** 18; // 10^18 is considered 1 in the price feed to allow for decimal calculations
    uint64 internal constant MAX_UINT64 = uint64(-1);
    uint256 internal constant MAX_ACCRUED_VALUE = 2**128;

    string private constant ERROR_NO_EMPLOYEE = "PAYROLL_NO_EMPLOYEE";
    string private constant ERROR_EMPLOYEE_DOES_NOT_MATCH = "PAYROLL_EMPLOYEE_DOES_NOT_MATCH";
    string private constant ERROR_FINANCE_NOT_CONTRACT = "PAYROLL_FINANCE_NOT_CONTRACT";
    string private constant ERROR_TOKEN_ALREADY_ALLOWED = "PAYROLL_TOKEN_ALREADY_ALLOWED";
    string private constant ERROR_ACCRUED_VALUE_TOO_BIG = "PAYROLL_ACCRUED_VALUE_TOO_BIG";
    string private constant ERROR_TOKEN_ALLOCATION_MISMATCH = "PAYROLL_TOKEN_ALLOCATION_MISMATCH";
    string private constant ERROR_NO_ALLOWED_TOKEN = "PAYROLL_NO_ALLOWED_TOKEN";
    string private constant ERROR_DISTRIBUTION_NO_COMPLETE = "PAYROLL_DISTRIBUTION_NO_COMPLETE";
    string private constant ERROR_NOTHING_PAID = "PAYROLL_NOTHING_PAID";
    string private constant ERROR_EMPLOYEE_ALREADY_EXIST = "PAYROLL_EMPLOYEE_ALREADY_EXIST";
    string private constant ERROR_EMPLOYEE_NULL_ADDRESS = "PAYROLL_EMPLOYEE_NULL_ADDRESS";
    string private constant ERROR_NO_FORWARD = "PAYROLL_NO_FORWARD";
    string private constant ERROR_FEED_NOT_CONTRACT = "PAYROLL_FEED_NOT_CONTRACT";
    string private constant ERROR_EXPIRY_TIME_TOO_SHORT = "PAYROLL_EXPIRY_TIME_TOO_SHORT";
    string private constant ERROR_EXCHANGE_RATE_ZERO = "PAYROLL_EXCHANGE_RATE_ZERO";
    string private constant ERROR_PAST_TERMINATION_DATE = "PAYROLL_PAST_TERMINATION_DATE";

    event AddAgreement(
        bytes32 agreementId,
        address receiver,
        address payor,
        address token,
        uint256 annualAmount,
        uint256 startDate,
        string description
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
      uint256 denominationTokenPayPerSecond; // per second in denomination token
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
      agreement.denominationTokenPayPerSecond = annualAmount / 325.25 days;
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
