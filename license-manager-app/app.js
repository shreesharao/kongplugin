const express = require('express')
const app = express()
const port = 5000

app.post('/api/license/acquire', (req, res) => {
  console.log(`Got request on path ${req.url}, port ${req.socket.remotePort} from host ${req.hostname}`)
  res.send('\{"mode":"Blocked"\}')
})

app.listen(port, () => {
  console.log(`LM app listening on port ${port}`)
})