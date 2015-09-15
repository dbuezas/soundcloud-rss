express = require 'express'
http = require 'http'
fs = require 'fs'
Podcast = require 'podcast'
request = require 'request'

client_id1 = 'b45b1aa10f1ac2941910a7f0d10f8e28'
client_id2 = 'a3e059563d7fd3372b49b37f00a00bcf'
app = express()
server = null

app.get ['/', '/rss/'], (req, res) ->
  prefix = "http://#{server.address().address}:#{server.address().port}/[username]/"
  res.send "usage:<br>
    #{prefix}tracks<br>
    #{prefix}favorites<br>
    #{prefix}playlists/[playlist_name]
    "

app.get '/rss/*', (req, res) ->
  try
    route = req.originalUrl.substr 5
    feed = new Podcast
      title: route
      itunesImage:'http://www.jasonmasi.com/sites/default/files/public/images/soundcloud-icon.png'

    request
      url: "http://api.soundcloud.com/users/#{route}?client_id=#{client_id1}"
      json: yes
    , (err, res1, songs) ->
      return res.send err if err?
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
              url: o.stream_url + '?client_id=' + client_id2
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
