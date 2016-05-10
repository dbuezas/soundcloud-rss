express = require 'express'
http = require 'http'
fs = require 'fs'
Podcast = require 'podcast'
request = require 'request'

client_id = '02gUJC0hH2ct1EGOcYXQIzRFU91c72Ea'
app = express()
server = null

app.get ['/'], (req, res) ->
  str = "#{server.address().address}:#{server.address().port}"
  #https://api.soundcloud.com/resolve?url=https%3A//soundcloud.com/david-buezas/sets/sport&client_id=02gUJC0hH2ct1EGOcYXQIzRFU91c72Ea
  if process.env.OPENSHIFT_NODEJS_IP?
    str = "#{process.env.OPENSHIFT_NODEJS_IP}:#{process.env.OPENSHIFT_NODEJS_PORT}/"
  str = "http://#{prefix}/rss?url=[soundcloud-url]&client_id=[your_client_id(optional)]"
  res.send "usage:<br>#{str}"

app.get '/rss', (req, res) ->
  unless req.query.url?
    return res.redirect '/'
  try
    feed = new Podcast
      title: req.query.url.split('soundcloud.com/')[1]
      itunesImage:'http://www.jasonmasi.com/sites/default/files/public/images/soundcloud-icon.png'
    req.query.client_id ?= client_id
    request
      url: "http://api.soundcloud.com/resolve"
      qs: req.query
      json: yes
    , (err, res1, songs) ->
      return res.send err if err?
      if songs.errors?
        res.set 'Content-Type', 'text/plain'
        return res.send JSON.stringify res1, null, 2
      try
        return JSON.stringify(songs)
        (songs.tracks or songs).forEach (o) ->
          secs = Math.floor(o.duration / 1000)
          mins = Math.floor(secs / 60)
          hours = Math.floor(mins / 60)
          feed.item
            title: o.title
            description: "
              <img align='left' hspace='5' src='#{o.artwork_url}'/>
              [▶#{o.playback_count} ⬇#{o.download_count} 💬#{o.comment_count} ❤#{o.likes_count} 🔁#{o.reposts_count}]\n
              #{o.description}
            "
            guid: o.stream_url
            url: o.permalink_url
            author: o.label_name
            date: o.last_modified
            enclosure:
              url: o.stream_url + '?client_id=' + client_id
              size: o.original_content_size
              type: 'audio/mpeg'
            itunesImage: o.artwork_url.replace('https://','http://')
            itunesExplicit: no
            itunesAuthor: o.label_name
            itunesSummary: o.description
            itunesDuration: "#{hours}:#{mins%60}:#{secs%60}"
        res.set 'Content-Type', 'text/xml'
        res.send feed.xml()
      catch e then res.status(500).send e.toString()
  catch e then res.status(500).send e.toString()

port = process.env.OPENSHIFT_NODEJS_PORT or process.env.PORT or 8080
ip = process.env.OPENSHIFT_NODEJS_IP or '127.0.0.1'

server = http.createServer(app).listen port, ip, ->
  console.log "http://#{server.address().address}:#{server.address().port}"
