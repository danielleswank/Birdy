deg2rad = (degrees) ->
  return degrees * (Math.PI / 180)

rad2deg = (radians) ->
  return radians * (180 / Math.PI)

# original function: http://stackoverflow.com/questions/2628039/php-library-calculate-a-bounding-box-for-a-given-lat-lng-location
# original formula: http://www.movable-type.co.uk/scripts/latlong.html
get_bounding_box = (lat_deg, lon_deg, distance_miles) ->

    # earth in miles
    radius = 3963.1

    # bearings 
    due_north = 0
    due_south = 180
    due_east = 90
    due_west = 270

    # convert latitude/longitude to radians 
    lat_rad = deg2rad(lat_deg)
    lon_rad = deg2rad(lon_deg)

    # find the northmost, southmost, eastmost and westmost corners distance_miles away
    north_rad = Math.asin(Math.sin(lat_rad) * Math.cos(distance_miles / radius) + Math.cos(lat_rad) * Math.sin(distance_miles / radius) * Math.cos(due_north))
    south_rad = Math.asin(Math.sin(lat_rad) * Math.cos(distance_miles / radius) + Math.cos(lat_rad) * Math.sin(distance_miles / radius) * Math.cos(due_south))

    east_rad = lon_rad + Math.atan2(Math.sin(due_east) * Math.sin(distance_miles / radius) * Math.cos(lat_rad), Math.cos(distance_miles / radius) - Math.sin(lat_rad) * Math.sin(lat_rad))
    west_rad = lon_rad + Math.atan2(Math.sin(due_west) * Math.sin(distance_miles / radius) * Math.cos(lat_rad), Math.cos(distance_miles / radius) - Math.sin(lat_rad) * Math.sin(lat_rad))

    north_deg = rad2deg(north_rad)
    south_deg = rad2deg(south_rad)
    east_deg = rad2deg(east_rad)
    west_deg = rad2deg(west_rad)

    # sort the lat and long so that we can use them for a between query        
    if north_deg > south_deg
      lat1 = south_deg
      lat2 = north_deg
    else
      lat1 = north_deg
      lat2 = south_deg

    if east_deg > west_deg
      lon1 = west_deg
      lon2 = east_deg
    else
      lon1 = east_deg
      lon2 = west_deg

    return [lat1, lat2, lon1, lon2]

parse_message = (message) ->
  message = message.replace(/\b((?:https?:\/\/|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))/gi, '<a href="$&">$&</a>')
    .replace(/(^|\s)(@([a-z0-9_]+))/gi, '$1<a href="https://twitter.com/$3">$2</a>')
    .replace /(^|\s)(#([a-z0-9_]+))/gi, ($0, $1, $2, $3) ->
      return "#{$1}<a href=\"https://twitter.com/search/#{encodeURIComponent($3)}\">#{$2}</a>"

$ ->

  tweet_template = _.template(document.getElementById('tweet-template').innerHTML)
  tag_template = _.template(document.getElementById('search-item-template').innerHTML)

  $tweets = $('#tweets')
  $screen_name = $('#screen_name')

  $search_input = $('#search_input')
  $search_last = $('#search_box li:last-child')

  
  socket = io.connect()

  socket.on 'connect', ->
    console.log 'connect'

  socket.on 'tweet', (tweet) ->
    console.log tweet
    $tweets.prepend(tweet_template(tweet))
    $tweets.filter(':gt(139)').remove() if $tweets.length > 140
    
  socket.on 'error', (err) ->
    console.error err
    
  socket.on 'screen_name', (screen_name) ->
    console.log screen_name
    $screen_name.text(screen_name)

  
  track = []
  location = {}

  parse_text = (text) ->
    tag = {}
    tag.text = text = text.replace(/^\s+|\s+$/g, '')
    
    if (/^(\+|\-)?(\d+(\.\d+)?)(?:,)(\+|\-)?(\d+(\.\d+)?)$/.exec(text))
      tag.type = 'flag'
      [lat, lng] = tag.text.split(',')
      location[text] = get_bounding_box(lat, lng, 10)
    else
      tag.type = if /^@[A-Z0-9.-]+/i.exec(text) then 'user' else 'tag'
      track.push(text)

    $search_last.before(tag_template(tag))


  $search_input.bind 'keyup', (e) ->
    return unless e.keyCode in [9, 13, 32] # [tab, enter, space] 

    e.preventDefault()
    
    parse_text(e.target.value)
    
    e.target.value = ''
    
    # if e.keyCode is 13
      # socket.emit('search', track: track.join(' '), location: location.join(','))
    
  $search_input.bind 'blur', (e) ->
    
    parse_text(e.target.value)
    
    e.target.value = ''
