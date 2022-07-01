const express = require('express')
const app = express()
const port = 3000

app.get('/sysconfig', (req, res) => {
  console.log(`Got request on path ${req.url}, port ${req.socket.remotePort} from host ${req.hostname}`)
  res.send('Hello World From system config!')
})

app.get('/redirect', (req, res) => {
  console.log(`Got request on path ${req.url}, port ${req.socket.remotePort} from host ${req.hostname}`)
  res.send('Hello World From redirect!')
})

app.get('/logout', (req, res) => {
  console.log(`Got request on path ${req.url}, port ${req.socket.remotePort} from host ${req.hostname}`)
  res.send('Hello World From logout!')
})

app.get('*', (req, res) => {
  console.log(`Got request on path ${req.url}, port ${req.socket.remotePort} from host ${req.hostname}`)
  res.send('Hello World!')
})



app.listen(port, () => {
  console.log(`Express app listening on port ${port}`)
})