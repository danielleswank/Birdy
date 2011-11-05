config = require('./config')
store = require('./store').store

OAuth = require('oauth').OAuth
Firehose = require('./firehose').Firehose

exports.connect = (req, res) ->

  oauth = new OAuth(config.request_url, config.access_url, config.consumer_key, config.consumer_secret, '1.0A', config.callback_url, 'HMAC-SHA1')

  oauth.getOAuthRequestToken (err, oauth_token, oauth_token_secret, results) ->

    if err
      # res.send(err.message, 500)
      res.redirect('/500')
      return

    req.session.oauth_request_token = oauth_token
    req.session.oauth_request_token_Secret = oauth_token_secret

    res.redirect("https://twitter.com/oauth/authorize?oauth_token=#{req.session.oauth_request_token}")


exports.callback = (req, res) ->

  oauth = new OAuth(config.request_url, config.access_url, config.consumer_key, config.consumer_secret, '1.0A', config.callback_url, 'HMAC-SHA1')

  oauth.getOAuthAccessToken req.session.oauth_request_token, req.session.oauth_request_token_secret, req.query.oauth_verifier, (err, oauth_access_token, oauth_access_token_secret, results) ->

    if err
      # res.send(err.message, 500)
      res.redirect('/500')
      return

    req.session.oauth_access_token = oauth_access_token
    req.session.oauth_access_token_secret = oauth_access_token_secret

    req.session.screen_name = results['screen_name']
    res.redirect('/')


exports.connection = (socket) ->
  
  store.get socket.handshake.sessionId, (err, session) ->

    return unless session?.screen_name
    
    socket.emit('screen_name', session.screen_name)

    console.log session
    
    firehose = new Firehose(session)
    
    firehose.on 'tweet', (tweet) ->
      console.log tweet
      socket.emit('tweet', tweet)
        
    firehose.on 'error', (err) ->
      console.log err?.message
      socket.emit('error', err?.message)

    socket.on 'search', (query) ->
      console.log query
      if query?.track?.replace(/^\s+|\s+$/)
        firehose.request(query)
      else
        firehose.kill()

    socket.on 'disconnect', ->
      console.log 'dying...'
      firehose.kill()