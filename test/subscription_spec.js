/*global contract, config, it, assert*/
const utils = require('../utils/testUtils.js');
const finance = require('../utils/finance.js');
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

const annuityDue = (P, R, T) => {
  const e = Math.E
  const num = e**(R*T) - 1
  const den = e**R - 1
  return P * (num/den)
}

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
      const approval = await TestToken.methods.approve(Subscription.address, toWei("1000000")).send({from: payor})
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

    it('should compute annuity due correctly',  async function() {
      const owedWithInterest = await Subscription.methods.getAnnuityDueWrapper(
        toWei('1000'),
        '1',
        '12'
      ).call({from: receiver})

      const localOwed = annuityDue(1000, 0.01, 12);
      const truncated = Math.trunc(owedWithInterest * 1e-18)
      assert(Math.trunc(owedWithInterest * 1e-18) == Math.trunc(localOwed), `OwedWihInterest of ${truncated} does not match locally computed of ${Math.trunc(localOwed)}`)
    })

    it('should get correct amount owed to payee from agreementId', async function() {
      const { computeInterest } = finance;
      const elapsedTime = SECONDS_IN_A_YEAR + 10;
      const payPerSecond = annualSalary / elapsedTime;
      const rate = 0.04 / SECONDS_IN_A_YEAR;
      const accrued = elapsedTime * payPerSecond;
      await utils.increaseTime(SECONDS_IN_A_YEAR)
      const agreement = await Subscription.methods.getAgreement(
        returnValues.agreementId
      ).call()

      const computedAnnuityDue = annuityDue(payPerSecond, rate, elapsedTime)
      const owed = await Subscription.methods.getOwedById(
        returnValues.agreementId
      ).call({from: receiver})

      const truncAnnuityDue = Math.trunc(computedAnnuityDue * 1e-18);
      const truncOwed = Math.trunc(owed * 1e-18);
      assert(truncAnnuityDue == truncOwed, 'Amount owed does not equal locally computed value')
    })

    it('should allow a payor to supply token', async function() {
      const amount = toWei('110000')
      const supply = await Subscription.methods.supply(
        amount
      ).send({ from: payor })
      const returned = supply.events.SupplyReceived.returnValues
      assert.equal(amount, returned.amount, 'returned amount does not match')
    })

    it('should allow the receiver to withdraw funds accrued', async function() {
      const owed = await Subscription.methods.getOwedById(
        returnValues.agreementId
      ).call({from: receiver})

      const withdrawn = await Subscription.methods.withdrawFundsPayee(
        returnValues.agreementId
      ).send({ from: receiver })
      const returned = withdrawn.events.WithdrawFunds
      const withdrawAmount = returned.returnValues.amount
      assert(withdrawAmount === owed, 'withdrawn amount does not match amount owed')
    })

    //TODO allow payor to withdraw funds and terminate subscription.
    //TODO allow receiver to terminate subscription
    //TODO allow receiver to deny agreement
  })
})
