import React from 'react';
import Button from '@material-ui/core/Button';
import { withStyles } from '@material-ui/core/styles';
import { Link } from 'react-router-dom';
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
  title: {
    display: 'grid',
    fontSize: '3rem',
    gridColumnStart: '1',
    gridColumnEnd: '13',
    gridRowStart: '1',
    gridRowEnd: '6',
    textAlign: 'center',
    [theme.breakpoints.up('sm')]: {
      fontSize: '10rem'
    }

  },
  button: {
    gridColumnStart: '1',
    gridColumnEnd: '13',
    height: '4rem',
    fontSize: '1rem',
    [theme.breakpoints.up('sm')]: {
      fontSize: '3rem',
      height: '10rem'
    }
  },
  link: {
    display: 'grid',
    gridColumnStart: '1',
    gridColumnEnd: '13',
    textDecoration: 'none'
  }
})

const Title = ({ className }) => (
  <div className={className}>
    <div style={{ alignSelf: 'center' }}>Subscriptions</div>
    <Divider />
  </div>
)

function MainMenu({ classes, history }) {
  return (
    <div className={classes.root}>
      <Title className={classes.title} />
      <Link to={`/create-subscription`} className={classes.link}>
        <Button type="submit" color="primary" variant="contained" className={classes.button}>Create Subscription</Button>
      </Link>
      <Link to={`/view-subscriptions`} className={classes.link}>
        <Button type="submit" color="secondary" variant="contained" className={classes.button}>Your Subscribers</Button>
      </Link>
    </div>
  )
}

const StyledMenu = withStyles(styles)(MainMenu)
export default StyledMenu
