canvas = document.getElementsByTagName('canvas')[0]
canvas.width = 1024
canvas.height = 768

ctx = canvas.getContext '2d'

ws = new WebSocket "ws://#{window.location.host}"
ws.onerror = (e) -> console.error e

dt = 33

players = {}
boss = {}

cursorimg = new Image
cursorimg.src = 'cursor.png'

username = if window.location.hash
  window.location.hash.substr(1)
else
  prompt "Name="
window.location.hash = username

self = players[username] =
  alive: false

requestAnimationFrame = window.requestAnimationFrame or window.mozRequestAnimationFrame or
                        window.webkitRequestAnimationFrame or window.msRequestAnimationFrame

update = ->

draw = ->
  ctx.fillStyle = 'black'
  ctx.fillRect 0, 0, canvas.width, canvas.height

  ctx.save()

  if boss.x?
    ctx.fillStyle = boss.color
    ctx.beginPath()
    ctx.arc boss.x, boss.y, boss.radius, 0, 2*Math.PI, false
    ctx.fill()
  
  for name,p of players
    continue unless p.x?
    ctx.fillStyle = 'white'
    ctx.fillText name, p.x, p.y - 20
    if p.attacking and p.alive
      ctx.fillStyle = 'red'
      ctx.fillRect p.x-20, p.y-20, 50, 50
      p.attacking = false
    ctx.globalAlpha = 0.5 unless p.alive
    ctx.drawImage cursorimg, p.x, p.y
    ctx.globalAlpha = 1
    #ctx.fillRect p.x, p.y, 10, 10

  if boss.hp?
    ctx.fillStyle = 'gray'
    ctx.fillRect 10, 10, canvas.width - 20, 10
    ctx.fillStyle = 'red'
    ctx.fillRect 10, 10, (canvas.width - 20) * boss.hp/boss.maxhp, 10
  ctx.restore()

runFrame = ->
  setTimeout runFrame, dt
  update()
  requestAnimationFrame draw

ws.onmessage = (msg) ->
  msg = JSON.parse msg.data
  if msg.start?
    p.alive = true for n,p of players
    self.alive = true
  if msg.boss?
    for k,v of msg.boss
      boss[k] = v
  if msg.color?
    boss.color = msg.color
  if msg.x?
    p = (players[msg.name] ?= {})
    {x:p.x, y:p.y} = msg
    p.attacking ||= msg.attack

  if msg.alive?
    if msg.name is username
      self.alive = msg.alive
    else
      p = (players[msg.name] ?= {})
      p.alive = msg.alive



send = (msg) -> ws.send JSON.stringify msg

rateLimit = (fn) ->
  queuedMessage = false
  ->
    return if queuedMessage
    queuedMessage = true
    setTimeout ->
        queuedMessage = false
        fn()
      , 50

ws.onopen = ->
  console.log 'open'
  send {name:username}
  runFrame()

downKeys = {}

canvas.onmousemove = (e) ->
  x = e.pageX - canvas.offsetLeft
  y = e.pageY - canvas.offsetTop

  [self.x, self.y] = [x, y]
  send {x, y}

canvas.onmousedown = (e) ->
  x = e.pageX - canvas.offsetLeft
  y = e.pageY - canvas.offsetTop

  self.attacking = true
  send {attack:true, x, y}

document.onkeydown = (e) ->
  if e.keyCode == 32
    send {start:true}
