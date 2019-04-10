import React from 'react';
import ReactDOM from 'react-dom';
import { HashRouter as Router, Route, Link, Switch } from 'react-router-dom';
import { withStyles } from '@material-ui/core/styles';
import Divider from '@material-ui/core/Divider';

import EmbarkJS from 'Embark/EmbarkJS';
import Blockchain from './components/blockchain';
import Whisper from './components/whisper';
import Storage from './components/storage';
import ENS from './components/ens';
import MainMenu from './components/MainMenu';

const styles = theme => ({
  root: {
    display: 'grid',
    gridTemplateColumns: 'repeat(12, [col] 1fr)',
    gridTemplateRows: 'repeat(5, [row] auto)',
    gridColumnGap: '1em',
    gridRowGap: '3ch',
    fontFamily: theme.typography.fontFamily,
    [theme.breakpoints.up('sm')]: {
      margin: '1.75rem 4.5rem'
    }
  },
  title: {
    display: 'grid',
    fontSize: '10rem',
    gridColumnStart: '1',
    gridColumnEnd: '13',
    gridRowStart: '1',
    gridRowEnd: '6',
    textAlign: 'center'
  },
  buttons: {
    display: 'grid',
    fontSize: '2.5rem',
    gridColumnStart: '1',
    gridColumnEnd: '13',
    gridRowStart: '1',
    gridRowEnd: '6',
    textAlign: 'center'
  },
  textField: {
    gridColumnStart: '1',
    gridColumnEnd: '13'
  },
  textInput: {
    fontSize: '2rem'
  }
})

const Title = ({ className }) => (
  <div className={className}>
    <div style={{ alignSelf: 'center' }}>Subscriptions</div>
    <Divider />
  </div>
)

class App extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      error: null,
      activeKey: 1,
      whisperEnabled: false,
      storageEnabled: false,
      blockchainEnabled: false
    };
  }

  componentDidMount() {
    EmbarkJS.onReady((err) => {
      this.setState({blockchainEnabled: true});
      if (err) {
        // If err is not null then it means something went wrong connecting to ethereum
        // you can use this to ask the user to enable metamask for e.g
        return this.setState({error: err.message || err});
      }
    })
  }

  render() {
    const { classes } = this.props;
    return (
      <div className={classes.root}>
        <Title className={classes.title} />
        <Router className={classes.buttons}>
          <Switch>
            <Route path="/(|main)" component={MainMenu} />
          </Switch>
        </Router>
      </div>
    );
  }
}

const StyledApp = withStyles(styles)(App)
ReactDOM.render(<StyledApp />, document.getElementById('app'));
