import React from 'react'
import Layout from '../components/layout'
import url from '../url'

function colorForState (s) {
  switch (s) {
    case 'running':
      return 'limegreen'
    case 'stopped':
      return 'red'
    case 'starting':
    case 'stopping':
    case 'pending':
      return 'gold'
    default:
      return 'gray'
  }
}

class IndexPage extends React.Component {
  constructor (props) {
    super(props)

    this.state = { servers: [] }
    this.loadStatus = this.loadStatus.bind(this)
  }

  loadStatus () {
    fetch(`${url}/status`, {method: 'GET', mode: 'cors', credentials: 'omit'})
      .then(data => {
        data.json().then(s => {
          this.setState({servers: s || []})
        })
      }).catch(e => console.log('ERROR', e))
  }

  componentDidMount () {
    this.loadStatus()
    setInterval(this.loadStatus, 2000)
  }

  render () {
    return (<Layout>
      <h1>Minecraft Server Control</h1>

      <table>
        <tbody>
          {this.state.servers.map((s, i) => {
            return <tr key={s.ID}>
              <td>{i + 1}. {s.Name} ({s.ID})</td>
              <td>{s.Type}</td>
              <td style={{
                color: colorForState(s.State),
                fontWeight: 'bold'
              }}>
                {s.State}
              </td>
            </tr>
          })}
        </tbody>
      </table>

      <button className='btn btn-success' onClick={() => {
        fetch(`${url}/start`, {method: 'post', mode: 'cors', credentials: 'omit'}).then(this.loadStatus)
      }}>start all</button>

      <button className='btn btn-error' onClick={() => {
        fetch(`${url}/stop`, {method: 'post', mode: 'cors', credentials: 'omit'}).then(this.loadStatus)
      }}>stop all</button>
    </Layout>)
  }
}

export default IndexPage
