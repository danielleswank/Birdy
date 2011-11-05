(function() {
  var deg2rad, get_bounding_box, parse_message, rad2deg;
  deg2rad = function(degrees) {
    return degrees * (Math.PI / 180);
  };
  rad2deg = function(radians) {
    return radians * (180 / Math.PI);
  };
  get_bounding_box = function(lat_deg, lon_deg, distance_miles) {
    var due_east, due_north, due_south, due_west, east_deg, east_rad, lat1, lat2, lat_rad, lon1, lon2, lon_rad, north_deg, north_rad, radius, south_deg, south_rad, west_deg, west_rad;
    radius = 3963.1;
    due_north = 0;
    due_south = 180;
    due_east = 90;
    due_west = 270;
    lat_rad = deg2rad(lat_deg);
    lon_rad = deg2rad(lon_deg);
    north_rad = Math.asin(Math.sin(lat_rad) * Math.cos(distance_miles / radius) + Math.cos(lat_rad) * Math.sin(distance_miles / radius) * Math.cos(due_north));
    south_rad = Math.asin(Math.sin(lat_rad) * Math.cos(distance_miles / radius) + Math.cos(lat_rad) * Math.sin(distance_miles / radius) * Math.cos(due_south));
    east_rad = lon_rad + Math.atan2(Math.sin(due_east) * Math.sin(distance_miles / radius) * Math.cos(lat_rad), Math.cos(distance_miles / radius) - Math.sin(lat_rad) * Math.sin(lat_rad));
    west_rad = lon_rad + Math.atan2(Math.sin(due_west) * Math.sin(distance_miles / radius) * Math.cos(lat_rad), Math.cos(distance_miles / radius) - Math.sin(lat_rad) * Math.sin(lat_rad));
    north_deg = rad2deg(north_rad);
    south_deg = rad2deg(south_rad);
    east_deg = rad2deg(east_rad);
    west_deg = rad2deg(west_rad);
    if (north_deg > south_deg) {
      lat1 = south_deg;
      lat2 = north_deg;
    } else {
      lat1 = north_deg;
      lat2 = south_deg;
    }
    if (east_deg > west_deg) {
      lon1 = west_deg;
      lon2 = east_deg;
    } else {
      lon1 = east_deg;
      lon2 = west_deg;
    }
    return [lat1, lat2, lon1, lon2];
  };
  parse_message = function(message) {
    return message = message.replace(/\b((?:https?:\/\/|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))/gi, '<a href="$&">$&</a>').replace(/(^|\s)(@([a-z0-9_]+))/gi, '$1<a href="https://twitter.com/$3">$2</a>').replace(/(^|\s)(#([a-z0-9_]+))/gi, function($0, $1, $2, $3) {
      return "" + $1 + "<a href=\"https://twitter.com/search/" + (encodeURIComponent($3)) + "\">" + $2 + "</a>";
    });
  };
  $(function() {
    var $search_input, $search_last, $tweets, add_tag, build_locations, location, remove_tag, socket, tag_template, track, tweet_template;
    tweet_template = _.template(document.getElementById('tweet-template').innerHTML);
    tag_template = _.template(document.getElementById('search-item-template').innerHTML);
    $tweets = $('#tweets');
    $search_input = $('#search_input');
    $search_last = $('#search_box li:last-child');
    socket = io.connect();
    socket.on('connect', function() {
      return console.log('connect');
    });
    socket.on('tweet', function(tweet) {
      console.log(tweet);
      $tweets.prepend(tweet_template(tweet));
      if ($tweets.length >= 140) {
        return $tweets.filter(':gt(139)').remove();
      }
    });
    socket.on('error', function(err) {
      return console.error(err);
    });
    socket.on('screen_name', function(screen_name) {
      console.log(screen_name);
      $('#sign_in').hide(100);
      $('#search, #see_tweets').show(100);
      return $('#screen_name').text(screen_name);
    });
    track = [];
    location = {};
    build_locations = function(locations) {
      var locations_all;
      locations_all = _.reduce(locations, function(locations_all, location) {
        return locations_all.concat(location);
      }, []);
      console.log(locations_all);
      if (locations_all.length) {
        return locations_all;
      } else {
        return '';
      }
    };
    add_tag = function(text) {
      var $tag, lat, lng, tag, tag_el, _ref;
      tag = {};
      tag.text = text;
      if (/^(\+|\-)?(\d+(\.\d+)?)(?:,)(\+|\-)?(\d+(\.\d+)?)$/.exec(text)) {
        tag.type = 'flag';
        _ref = tag.text.split(','), lat = _ref[0], lng = _ref[1];
        location[text] = get_bounding_box(lat, lng, 25);
      } else {
        tag.type = /^@[A-Z0-9.-]+/i.exec(text) ? 'user' : 'tag';
        track.push(text);
      }
      tag_el = document.createElement('li');
      tag_el.className = "" + tag.type + " search_item";
      tag_el.innerHTML = tag_template(tag);
      $tag = $(tag_el);
      $tag.find('.remove').bind('click', function(e) {
        console.log('remove');
        remove_tag(text, false);
        return socket.emit('search', {
          track: track.join(' '),
          location: build_locations(location)
        });
      });
      $tag.find('.toggle').bind('click', function(e) {
        console.log('toggle');
        $tag.toggleClass('inactive');
        remove_tag(text, true);
        return socket.emit('search', {
          track: track.join(' '),
          location: build_locations(location)
        });
      });
      $search_last.before(tag_el);
      return '';
    };
    remove_tag = function(text, toggle) {
      var $element, index;
      if (text === '') {
        $element = $search_last.prev();
        text = $element.find('.toggle').text();
      } else {
        $element = $('#search_box .toggle:contains(' + text + ')').parent('li');
      }
      if (toggle !== true) {
        $element.remove();
      }
      if (/^(\+|\-)?(\d+(\.\d+)?)(?:,)(\+|\-)?(\d+(\.\d+)?)$/.exec(text)) {
        delete location[text];
      } else {
        index = track.indexOf(text);
        delete track[index];
      }
      return text;
    };
    $search_input.bind('keyup', function(e) {
      var text, _ref, _ref2;
      if ((_ref = e.keyCode) !== 9 && _ref !== 13 && _ref !== 32 && _ref !== 8) {
        return;
      }
      e.preventDefault();
      text = e.target.value.replace(/^\s+|\s+$/g, '');
      if (e.keyCode === 8 && e.target.value === '') {
        e.target.value = remove_tag(text, false);
      }
      if ((_ref2 = e.keyCode) === 9 || _ref2 === 13 || _ref2 === 32) {
        e.target.value = add_tag(text);
      }
      if (e.keyCode === 13) {
        return socket.emit('search', {
          track: track.join(' '),
          location: build_locations(location)
        });
      }
    });
    return $search_input.bind('blur', function(e) {
      parse_text(e.target.value);
      return e.target.value = '';
    });
  });
}).call(this);
