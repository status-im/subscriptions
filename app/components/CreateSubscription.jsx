import React, { useState, useEffect } from 'react';
import Button from '@material-ui/core/Button';
import { Formik } from 'formik'
import Subscription from 'Embark/contracts/Subscription';
import {default as DAI} from 'Embark/contracts/TestToken';
import TextField from '@material-ui/core/TextField'
import { withStyles } from '@material-ui/core/styles';
import Divider from '@material-ui/core/Divider';

const { createAgreement } = Subscription.methods;

const validate = async (values) => {
  const { amount } = values
  let errors = {}
  const formattedAmount = web3.utils.toWei(amount)
  const payor = await web3.eth.getCoinbase()
  const balance = await DAI.methods.balanceOf(payor).call()
  const validAmount = BigInt(formattedAmount) <= BigInt(balance)
  if (!validAmount) errors.amount = 'Insufficient amount of DAI in account'
  if (Object.keys(errors).length) throw errors
}

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
  textField: {
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
  textInput: {
    fontSize: '2rem'
  }
})

const Title = ({ className }) => (
  <div className={className}>
    <div style={{ alignSelf: 'center' }}>Create Subscription</div>
    <Divider />
  </div>
)

async function checkAndSetAllowance(setAllowance) {
  const payor = await web3.eth.getCoinbase()
  const approved = await DAI.methods.allowance(payor, Subscription.address).call()
  setAllowance(approved)
}

async function approveTransfers(setAllowance) {
  const payor = await web3.eth.getCoinbase()
  const balance = await DAI.methods.balanceOf(payor).call()
  DAI
    .methods
    .approve(Subscription.address, balance).send()
    .then(res => { setAllowance(balance)})
    .catch(console.log)
}

function CreateSubscription({ classes, history }) {
  const [allowance, setAllowance] = useState(0)

  useEffect(() => {
    checkAndSetAllowance(setAllowance)
  }, [])
  console.log({allowance}, !!Number(allowance))

  return (
    <Formik
      initialValues={{
        receiver: '',
        amount: '',
        description: '',
      }}
      validate={validate}
      onSubmit={async (values, { resetForm }) => {
        console.log({values,Subscription, DAI}, DAI.address)
        const { receiver, amount, description } = values
        // Start immediately
        const startDate = "0"
        const payor = await web3.eth.getCoinbase()
        const approved = await DAI.methods.allowance(payor, Subscription.address).call()
        const args = [
          receiver,
          payor,
          DAI.address,
          web3.utils.toWei(amount),
          startDate,
          description
        ]
        console.log({args, approved})
        createAgreement(...args)
               .send()
               .then(res => {
                 console.log({res})
                 resetForm()
               })
               .catch(err => {
                 console.log({err})
                 resetForm()
               })
      }}
    >
      {({
        values,
        errors,
        touched,
        handleChange,
        handleBlur,
        handleSubmit,
        setFieldValue,
        setStatus,
        status,
        isSubmitting
      }) => {
        return (
          <form onSubmit={handleSubmit} className={classes.submissionRoot}>
            <Title className={classes.title} />
            <TextField
              className={classes.textField}
              InputProps={{
                classes: {
                  input: classes.textInput
                }
              }}
              id="receiver"
              name="receiver"
              label="Address of receiver you are subscribing to"
              placeholder="Address of receiver you are subscribing to"
              margin="normal"
              variant="outlined"
              onChange={handleChange}
              onBlur={handleBlur}
              value={values.receiver || ''}
            />
            <TextField
              className={classes.textField}
              error={!!errors.amount}
              InputProps={{
                classes: {
                  input: classes.textInput
                }
              }}
              id="amount"
              name="amount"
              label={errors.amount ? "Insufficient Balance" : "The annual amount you will be paying in DAI"}
              placeholder="The annual amount you will be paying in DAI"
              margin="normal"
              variant="outlined"
              onChange={handleChange}
              onBlur={handleBlur}
              value={values.amount || ''}
            />
            <TextField
              id="description"
              name="description"
              className={classes.textField}
              InputProps={{
                classes: {
                  input: classes.textInput
                }
              }}
              label="Enter ipfs/swarm hash for documentation"
              placeholder="Enter ipfs/swarm hash for documentation"
              margin="normal"
              variant="outlined"
              onChange={handleChange}
              onBlur={handleBlur}
              value={values.description || ''}
            />
            {!!Number(allowance)
            ? <Button type="submit" color="primary" variant="contained" className={classes.formButton}>{isSubmitting ? 'Ethereum Submission In Progress' : 'Create Subscription'}</Button>
            : <Button color="secondary" variant="contained" className={classes.formButton} onClick={()=> { approveTransfers(setAllowance)}}>Grant DAI Transfer Permissions</Button>}
          </form>
        )
      }
      }
    </Formik>
  )
}

const StyleSubscription = withStyles(styles)(CreateSubscription)
export default StyleSubscription
