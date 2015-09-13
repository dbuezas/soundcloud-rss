express = require 'express'
http = require 'http'
fs = require 'fs'
Podcast = require 'podcast'
request = require 'request'

client_id1 = 'b45b1aa10f1ac2941910a7f0d10f8e28'
client_id2 = 'a3e059563d7fd3372b49b37f00a00bcf'
app = express()
app.get '/', (req, res) ->
  res.set 'Content-Type', 'text/xml'
  console.log 'processing: ', "https://api.soundcloud.com/users/#{req.query.s}?client_id=#{client_id1}"

  feed = new Podcast
    title: req.query.s
    itunesImage:'http://www.jasonmasi.com/sites/default/files/public/images/soundcloud-icon.png'

  request
    url: "http://api.soundcloud.com/users/#{req.query.s}?client_id=#{client_id1}"
    json: yes
  , (err, res1, songs) ->
    return console.err err if err?
    songs.forEach (o) ->
      secs = Math.floor(o.duration / 1000)
      mins = Math.floor(secs / 60)
      hours = Math.floor(mins / 60)
      feed.item
        title: o.title
        description: "
          <img align='left' hspace='5' src='#{o.artwork_url}'/>
          #{o.description}\n
          Plays: #{o.playback_count}\n
          Downloads: #{o.download_count}\n
          Favoritings: #{o.favoritings_count}\n
          Comments: #{o.comment_count}\n
          Likes: #{o.likes_count}\n
          Reposts: #{o.reposts_count}
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

    res.send feed.xml()

port = process.env.OPENSHIFT_NODEJS_PORT or process.env.PORT or 8080
ip = process.env.OPENSHIFT_NODEJS_IP or '127.0.0.1'

http.createServer(app).listen port, ip, ->
  console.log 'Example app listening at http://%s:%s', ip, port
