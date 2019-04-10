/*global contract, config, it, assert*/
const utils = require('../utils/testUtils.js');
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
      args: ["$Compound", "$TestToken"]
    },
    "TestToken": {
      args: []
    },
    "Compound": {}
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

  describe('createAgreement and supply withdraw flow', function() {
    const annualSalary = toWei("100000")
    let returnValues;

    it("should create an agreement", async function () {
      let balance = await web3.eth.getBalance(accounts[8])
      const args = [
        receiver,
        payor,
        TestToken.address,
        annualSalary,
        "0",
        "ipfs/hash"
      ]
      const agreementCreation = await Subscription.methods.createAgreement(
        ...args
      ).send({ from: payor })
      returnValues = agreementCreation.events.AddAgreement.returnValues
      args.slice(0,4).forEach((arg, i) => {
          const val = returnValues[i+1]
          assert.equal(val, arg, `${val} does not match arg ${arg}`)
      })
    });

    it('should get amount owed to receiver', async function() {
      const accrued = 10 * (annualSalary / SECONDS_IN_A_YEAR)
      await utils.increaseTime(10)
      const owed = await Subscription.methods.getAmountOwed(
        returnValues.agreementId
      ).call({from: receiver})
      assert.equal(owed, accrued, `Owned: ${owed} amount returned not equal to expected ${accrued}`)
    });

    it('should get interest owed from compound', async function() {
      const accrued = 1000 * 10 * (annualSalary / SECONDS_IN_A_YEAR)
      const approxInterest = accrued * (0.04 / 12 / 30 / 24)
      await utils.increaseTime(1000)
      const owed = await Subscription.methods.getInterestOwed(
        accrued.toString()
      ).call({from: receiver})
      const totalOwed = await Subscription.methods.getTotalOwed(
        returnValues.agreementId
      ).call({from: receiver})
      assert(owed < approxInterest, "The amount owed is higher than expected")
      assert(Number(totalOwed) >= Number(owed), "totalOwed can not be less than owed")
    })

    it('should allow a payor to supply token', async function() {
      const amount = toWei('100000')
      const supply = await Subscription.methods.supply(
        amount
      ).send({ from: payor })
      const returned = supply.events.SupplyReceived.returnValues
      assert.equal(amount, returned.amount, 'returned amount does not match')
    })

    it('should allow the receiver to withdraw funds accrued', async function() {
      const accrued = 1000 * 10 * (annualSalary / SECONDS_IN_A_YEAR)
      const approxInterest = accrued * (0.04 / 12 / 30 / 24)
      const totalOwed = await Subscription.methods.getTotalOwed(
        returnValues.agreementId
      ).call({from: receiver})
      const withdrawn = await Subscription.methods.withdrawFunds(
        returnValues.agreementId,
        totalOwed
      ).send({ from: receiver })
      const returned = withdrawn.events.WithdrawFunds
      assert.equal(Number(returned.returnValues.amount), Number(totalOwed), "withdraw failed or returned amount incorrect")
      const totalOwed2 = await Subscription.methods.getTotalOwed(
        returnValues.agreementId
      ).call({from: receiver})
      assert.equal(totalOwed2, "0", "Not all funds withdrawn")
    })

    //TODO allow payor to withdraw funds and terminate subscription.
    //TODO allow receiver to terminate subscription
  })
})
