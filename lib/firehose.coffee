url = require('url')
https = require('https')
qs = require('querystring')

_ = require('underscore')

config = require('./config')

OAuth = require('oauth').OAuth
EventEmitter = require('events').EventEmitter

build_api_request = (session, body) ->
  return null unless session

  request_url = 'https://stream.twitter.com/1/statuses/filter.json'
  request_url_parts = url.parse(request_url)

  oauth = new OAuth(config.request_token_url,
                    config.access_token_url,
                    config.consumer_key,
                    config.consumer_secret,
                    '1.0',
                    config.callback,
                    'HMAC-SHA1')

  oauth_token = session.oauth_access_token
  oauth_token_secret = session.oauth_access_token_secret

  ordered_params = oauth._prepareParameters(oauth_token, oauth_token_secret, 'POST', request_url, body)

  options =
    host: request_url_parts.hostname
    path: request_url_parts.pathname
    method: 'POST'
    port: 443
    headers:
      'Authorization': oauth._buildAuthorizationHeaders(ordered_params)
      'Host': request_url_parts.hostname
      'Content-length': qs.stringify(body).length
      'Content-Type': 'application/x-www-form-urlencoded'
      'connection': 'keep-alive'

  return options

# https://github.com/technoweenie/twitter-node

class exports.Firehose extends EventEmitter

  constructor: (@session) ->
  
  tweet: _.throttle (tweet) ->
    @emit('tweet', tweet)
  , 2000
  
  request: (body) ->
    options = build_api_request(@session, body)

    return unless options

    @response?.socket.end()

    request = https.request options, (@response) =>
      if response.statusCode isnt 200
        @emit('error', new Error('invalid status: ' + response.statusCode))
        response.socket.end()
        return

      buffer = ''

      response.on 'data', (data) =>
        buffer += data.toString('utf8')

        while (index = buffer.indexOf('\r\n')) > -1
          json = buffer.slice(0, index)
          buffer = buffer.slice(index + 2)

          continue if json.length <= 0

          try
            @tweet(JSON.parse(json))
          catch err
            @emit('error', err)

      response.on 'end', =>
        @emit('end', this)

      response.on 'close', (err) =>
        response.socket.end()
        @emit('close', err)
    
    request.on 'error', (err) ->
      @response.socket.end()
      @emit('error', err)

    request.end(qs.stringify(body))
    
  kill: ->
    @response?.socket.end()