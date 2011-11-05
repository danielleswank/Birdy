handlers = require('./lib/handlers')
express = require('express')
socket = require('socket.io')
store = require('./lib/store').store
app = express.createServer()

app.use(express.logger(format: '[:date] [:response-time] [:status] [:method] [:url]'))
app.use(express.bodyParser()) # pre-parses JSON body responses
app.use(express.cookieParser()) # pre-parses JSON cookies
app.use(express.session(secret: 'BIRDY', store: store, cookie: { path: '/', httpOnly: true, maxAge: 604800 })) # keep cookie for one week
app.use(express.compiler(src: "#{__dirname}/src", dest: "#{__dirname}/public", enable: ['coffeescript'])) # looks for cs files to render as js
app.use(express.static("#{__dirname}/public"))

app.get('/connect', handlers.connect)
app.get('/callback', handlers.callback)

io = socket.listen(app)

io.configure ->

  io.set('log level', 2)
  io.set 'authorization', (handshakeData, callback) ->
  
    sessionId = handshakeData.headers?.cookie?.replace(/.*connect.sid=(.+)(;|$)/, '$1')

    unless sessionId
      callback("invalid sessionId: #{sessionId}", false)
      return

    handshakeData.sessionId = decodeURIComponent(sessionId)

    callback(null, true)

io.sockets.on('connection', handlers.connection)

port = 80

app.listen(port)

console.log("listening on :#{port}")
