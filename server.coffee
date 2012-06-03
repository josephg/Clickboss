#http = require 'http'

express = require 'express'
app = express.createServer()

app.use express.static("#{__dirname}/")
port = 8123

# How frequently (in ms) should we advance the world
dt = 33
snapshotDelay = 5
bytesSent = bytesReceived = 0

WebSocketServer = require('ws').Server
wss = new WebSocketServer {server: app}

#state = 'menu' # Big button in the middle to start. Other state = 'playing'.

boss = require './boss'

b = null

setInterval ->
  b.update() if b?
, dt

players = {}

start = ->
  for name, p of players
    p.alive = true

  for cc in wss.clients
    cc.send JSON.stringify {start:true}

  b = boss players, (msg) ->
    s = JSON.stringify msg
    for cc in wss.clients
      bytesSent += s.length
      cc.send s


wss.on 'connection', (c) ->
  broadcast = (msg) ->
    s = JSON.stringify msg
    for cc in wss.clients when c isnt cc
      bytesSent += s.length
      cc.send s

  c.on 'message', (msg) ->
    bytesReceived += msg.length
    try
      msg = JSON.parse msg
      if msg.name?
        c.name = msg.name

      start() if msg.start

      p = (players[c.name] ?= {alive:false, x:0, y:0})

      if msg.attack and p.alive
        console.log 'attack!!'
        {x:p.x, y:p.y} = msg
        b.attackAt(p)
        broadcast {name:c.name, x:msg.x, y:msg.y, attack:true}
      else if msg.x?
        {x:p.x, y:p.y} = msg
        broadcast {name:c.name, x:msg.x, y:msg.y}


      #console.log msg

    catch e
      console.log 'invalid JSON', e, msg

setInterval ->
    console.log "TX: #{bytesSent}  RX: #{bytesReceived}"
    bytesSent = bytesReceived = 0
  , 1000

app.listen port
console.log "Listening on port #{port}"

