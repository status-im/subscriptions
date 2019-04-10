import React from 'react';
import Button from '@material-ui/core/Button';
import { Formik } from 'formik'
import Subscription from 'Embark/contracts/Subscription'
import TextField from '@material-ui/core/TextField'
import { withStyles } from '@material-ui/core/styles';
import Divider from '@material-ui/core/Divider';


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

function CreateSubscription({ classes, history }) {
  return (
    <Formik
      initialValues={{
        receiver: '',
        amount: '',
        description: '',
      }}
      onSubmit={async (values, { resetForm }) => {
        console.log({values,Subscription})
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
              InputProps={{
                classes: {
                  input: classes.textInput
                }
              }}
              id="amount"
              name="amount"
              label="The annual amount you will be paying in DAI"
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
            <Button type="submit" color="primary" variant="contained" className={classes.formButton}>{isSubmitting ? 'Ethereum Submission In Progress' : 'Create Subscription'}</Button>
          </form>
        )
      }
      }
    </Formik>
  )
}

const StyleSubscription = withStyles(styles)(CreateSubscription)
export default StyleSubscription
