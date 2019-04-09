/*global contract, config, it, assert*/
const Subscription = require('Embark/contracts/Subscription');
const TestToken = require('Embark/contracts/TestToken');

let accounts;
let payor;
let receiver;
const USD_DECIMALS= 18
const USD_PRECISION = 10**USD_DECIMALS
const SECONDS_IN_A_YEAR = 31557600 // 365.25 days
const ONE = 1e18
const ETH = '0x0'
const rateExpiryTime = 1000
const addAgreementStartDateIdx = 5

function getSalary(salary) {
  const amount = BigInt(salary);
  return (amount * BigInt(USD_PRECISION)) / BigInt(SECONDS_IN_A_YEAR)
}

const toWei = amt => web3.utils.toWei(amt, 'ether');

// For documentation please see https://embark.status.im/docs/contracts_testing.html
config({
  //deployment: {
  //  accounts: [
  //    // you can configure custom accounts with a custom balance
  //    // see https://embark.status.im/docs/contracts_testing.html#Configuring-accounts
  //  ]
  //},
  contracts: {
    "Subscription": {
      args: []
    },
    "TestToken": {
      args: []
    }
  }
}, (_err, web3_accounts) => {
  accounts = web3_accounts
  payor = web3_accounts[0]
  receiver = web3_accounts[1]
});


contract("subscription", function () {
  this.timeout(0);

  before(async function() {
    await TestToken.methods.mint(toWei('1000000')).send({from: payor})
  })

  describe('createAgreement', function() {
    it("should create an agreement", async function () {
      let balance = await web3.eth.getBalance(accounts[8])
      const args = [
        receiver,
        payor,
        TestToken.address,
        toWei("100000"),
        "0",
        "ipfs/hash"
      ]
      const agreementCreation = await Subscription.methods.createAgreement(
        ...args
      ).send({ from: payor })
      const returnValues = agreementCreation.events.AddAgreement.returnValues
      args.forEach((arg, i) => {
        const val = returnValues[i+1]
        if (!addAgreementStartDateIdx) {
          assert.equal(val, arg, `${val} does not match arg ${arg}`)
        }
      })
    });
  })

  });
