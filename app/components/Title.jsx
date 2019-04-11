import React from 'react'
import Divider from '@material-ui/core/Divider';

const Title = ({ className, name }) => (
  <div className={className}>
    <div style={{ alignSelf: 'center' }}>{name}</div>
    <Divider />
  </div>
)

export default Title
