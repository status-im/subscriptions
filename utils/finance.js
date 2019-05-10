const secondsInYear = 86400 * 365.25
exports.computeInterest = (annualSalary, elapsedTime, interestRate) => {
  // http://financeformulas.net/Future-Value-of-Annuity-Continuous-Compounding.html
  const salaryPerSecond = annualSalary / secondsInYear
  const intPerSecond = interestRate / (secondsInYear / elapsedTime)
  let E = Math.E
  const accruedInterest = salaryPerSecond * (E ** (intPerSecond * (elapsedTime / secondsInYear)) - 1) / (E ** intPerSecond - 1)
  return Math.round(accruedInterest)
}

exports.secondsInYear = secondsInYear;
