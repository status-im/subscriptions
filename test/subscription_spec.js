/*global contract, config, it, assert*/
const Subscription = require('Embark/contracts/Subscription');
const StandardToken = require('Embark/contracts/StandardToken');

let accounts;
let payor;
let receiver;
const USD_DECIMALS= 18
const USD_PRECISION = 10**USD_DECIMALS
const SECONDS_IN_A_YEAR = 31557600 // 365.25 days
const ONE = 1e18
const ETH = '0x0'
const rateExpiryTime = 1000

function getSalary(salary) {
  const amount = BigInt(salary);
  return (amount * BigInt(USD_PRECISION)) / BigInt(SECONDS_IN_A_YEAR)
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
      args: []
    },
    "StandardToken": {
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

  it("should create an agreement", async function () {
    //const salary1 = (new web3.BigNumber(100000)).times(USD_PRECISION).dividedToIntegerBy(SECONDS_IN_A_YEAR)

    let balance = await web3.eth.getBalance(accounts[8])
    console.log({accounts, balance}, StandardToken.options.address)
    // Subscription.methods.createAgreement(
    //   receiver,
    //   payor,
    //   StandardToken.address

    // )
  });

  });
