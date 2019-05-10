import React, { useState, useEffect } from 'react'
import Subscription from 'Embark/contracts/Subscription'
import Card from '@material-ui/core/Card'
import CardActions from '@material-ui/core/CardActions'
import CardContent from '@material-ui/core/CardContent'
import Typography from '@material-ui/core/Typography'
import Button from '@material-ui/core/Button'
import { withStyles } from '@material-ui/core/styles'
import Title from './Title'

const styles = theme => ({
  root: {
    display: 'grid',
    gridTemplateColumns: 'repeat(12, [col] 1fr)',
    gridTemplateRows: 'repeat(5, [row] auto)',
    gridColumnGap: '1em',
    gridRowGap: '3ch',
    gridColumnStart: '1',
    gridColumnEnd: '13',
    fontFamily: theme.typography.fontFamily
  },
  formButton: {
    gridColumnStart: '1',
    gridColumnEnd: '13',
    height: '4rem',
    fontSize: '1rem',
    [theme.breakpoints.up('sm')]: {
      fontSize: '3rem',
      height: '7rem'
    }
  },
  submissionRoot: {
    display: 'grid',
    gridTemplateColumns: 'repeat(12, [col] 1fr)',
    gridTemplateRows: 'repeat(5, [row] auto)',
    gridColumnGap: '1em',
    gridColumnStart: '1',
    gridColumnEnd: '13',
    gridRowGap: '2ch',
  },
  card: {
    gridColumnStart: '1',
    gridColumnEnd: '13'
  },
  title: {
    display: 'grid',
    fontSize: '3rem',
    gridColumnStart: '1',
    gridColumnEnd: '13',
    gridRowStart: '1',
    gridRowEnd: '6',
    textAlign: 'center',
    [theme.breakpoints.up('sm')]: {
      fontSize: '5rem'
    }
  },
  typography: {
    fontSize: '1rem'
  },
  accrued: {
    fontSize: '1rem',
    fontWeight: 'bold'
  },
  textInput: {
    fontSize: '2rem'
  }
})

async function addAgreementEvents(setState) {
  const pastEvents = await Subscription.getPastEvents('AddAgreement', {
    fromBlock: 1,
    toBlock: 'latest'
  })
  setState(pastEvents.map(e => e.returnValues))
}

async function enrichAgreement(agreement) {


}

const formatAmount = amt => amt ? web3.utils.fromWei(amt) : 0
const formatDate = date => new Date(Number(date)*1000);
const secondsDelta = (d1) => Math.abs((d1.getTime() - new Date().getTime()) / 1000);
const secondsInYear = 86400 * 365.25
const fetchInterestOwed = async (amountOwed, setState, agreementId) => {
  // TODO fetch interest owned and compare with computed interest
  const owed = await Subscription.methods.getInterestOwed(amountOwed).call()
  const amtOwed = await Subscription.methods.getAmountOwed(agreementId).call()
  console.log({owed, amtOwed})
  setState(owed)
}

const computeInterest = (annualSalary, elapsedTime, interestRate) => {
  // http://financeformulas.net/Future-Value-of-Annuity-Continuous-Compounding.html
  const salaryPerSecond = annualSalary / secondsInYear
  const intPerSecond = interestRate / (secondsInYear / elapsedTime)
  let E = Math.E
  const accruedInterest = salaryPerSecond * (E ** (intPerSecond * (elapsedTime / secondsInYear)) - 1) / (E ** intPerSecond - 1)
  return Math.round(accruedInterest)
}
const computeAndSetAccruedInterest = (annualAmount, startDate, interestRate, setState) => {
  const ellapsedTime = secondsDelta(formatDate(startDate))
  const accrued = computeInterest(annualAmount, ellapsedTime, interestRate)
  setState(accrued)
}
const computeAccrued = (annualAmt, secondsEllapsed) => {
  const amtPerSecond = annualAmt / secondsInYear
  const amount = amtPerSecond * secondsEllapsed
  return Math.round(amount)
}

const computeAndSetAccrued = (annualAmount, startDate, setState) => {
  const accrued = computeAccrued(annualAmount, secondsDelta(formatDate(startDate)))
  setState(accrued)
}

const SubscriptionInfo = ({ agreement, classes }) => {
  const { annualAmount, startDate, agreementId } = agreement
  const [accrued, setAccrued] = useState(0)
  const [accruedInterest, setAccruedInterest] = useState(0)
  const [onChainInterest, setOnChainInterest] = useState(0)
  const interestRate = 0.04
  useEffect(
    () => {
      let timer1 = setInterval(() => computeAndSetAccrued(annualAmount, startDate, setAccrued), 1000)
      let timer2 = setInterval(() => computeAndSetAccruedInterest(annualAmount, startDate, interestRate, setAccruedInterest), 1000)
      let timer3 = setInterval(() => fetchInterestOwed(accrued, setOnChainInterest, agreementId), 1000)
      return () => {
        clearTimeout(timer1)
        clearTimeout(timer2)
        clearTimeout(timer3)
      }
    }, [])
  return (
    <Card className={classes.card}>
      <CardContent>
        <Typography className={classes.typography} gutterBottom>
          Agreement Id
        </Typography>
        <Typography className={classes.typography} gutterBottom color="textSecondary">
          {agreement.agreementId}
        </Typography>
        <Typography className={classes.typography} gutterBottom>
          Subscriber
        </Typography>
        <Typography className={classes.typography} gutterBottom color="textSecondary">
          {agreement.payor}
        </Typography>
        <Typography className={classes.typography} gutterBottom>
          Annual Amount
        </Typography>
        <Typography className={classes.typography} gutterBottom color="textSecondary">
          {`${formatAmount(agreement.annualAmount)} DAI`}
        </Typography>
        <Typography className={classes.typography} gutterBottom>
          Active Since
        </Typography>
        <Typography className={classes.typography} gutterBottom color="textSecondary">
          {`${formatDate(agreement.startDate)}`}
        </Typography>
        <Typography className={classes.typography} gutterBottom>
          Accrued Amount
        </Typography>
        <Typography className={classes.accrued} gutterBottom>
          {`${Number(formatAmount(accrued.toString())).toLocaleString(undefined, {minimumFractionDigits: 5})} DAI`}
        </Typography>
        <Typography className={classes.typography} gutterBottom>
          Accrued Interest Earned
        </Typography>
        <Typography className={classes.accrued} gutterBottom>
          {`${Number(formatAmount(accruedInterest.toString())).toLocaleString(undefined, {minimumFractionDigits: 10})} DAI`}
        </Typography>
        <Typography className={classes.typography} gutterBottom>
          Onchain Interest Earned
        </Typography>
        <Typography className={classes.accrued} gutterBottom>
          {`${Number(formatAmount(onChainInterest.toString())).toLocaleString(undefined, {minimumFractionDigits: 10})} DAI`}
        </Typography>
      </CardContent>
      <CardActions>
        <Button size="small">Withdraw</Button>
      </CardActions>
    </Card>
  )
}

function ViewSubscriptions({ classes }) {
  const [addAgreements, setAgreements] = useState([])

  useEffect(() => {
    addAgreementEvents(setAgreements)
  }, [])
  console.log({addAgreements})
  return (
    <div className={classes.root}>
      <Title name='Your Subscribers' className={classes.title} />
      {addAgreements.map(agreement => <SubscriptionInfo key={agreement.agreementId} classes={classes} agreement={agreement} />)}
    </div>
  )
}

const StyledSubscriptions = withStyles(styles)(ViewSubscriptions)
export default StyledSubscriptions
