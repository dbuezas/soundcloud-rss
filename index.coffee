express = require 'express'
http = require 'http'
fs = require 'fs'
Podcast = require 'podcast'
request = require 'request'

client_id = '02gUJC0hH2ct1EGOcYXQIzRFU91c72Ea'
app = express()
server = null

app.get ['/', '/rss/'], (req, res) ->
  prefix = "#{server.address().address}:#{server.address().port}"
  if process.env.OPENSHIFT_NODEJS_IP?
    prefix = "#{process.env.OPENSHIFT_NODEJS_IP}:#{process.env.OPENSHIFT_NODEJS_PORT}/"
  prefix = "http://#{prefix}/rss/[username]/"
  posfix = '?client_id=[your_client_id(optional)]'
  res.send "usage:<br>
    #{prefix}tracks#{posfix}<br>
    #{prefix}favorites#{posfix}<br>
    #{prefix}playlists/[playlist_name]#{posfix}
    "

app.get '/rss/*', (req, res) ->
  client_id_replaced = req.query.client_id
  client_id_replaced ?= client_id

  try
    route = req.originalUrl.substr 5
    feed = new Podcast
      title: route
      itunesImage:'http://www.jasonmasi.com/sites/default/files/public/images/soundcloud-icon.png'

    request
      url: "http://api.soundcloud.com/users/#{route}?client_id=#{client_id}"
      json: yes
    , (err, res1, songs) ->
      return res.send err if err?
      if songs.errors?
        res.set 'Content-Type', 'text/plain'
        return res.send JSON.stringify res1, null, 2
      try
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
            itunesImage: o.artwork_url
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
