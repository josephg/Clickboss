
dist2 = (a, b) ->
  dx = a.x - b.x
  dy = a.y - b.y
  dx * dx + dy * dy

within = (a, b, dist) ->
  dist2(a, b) < dist * dist


module.exports = (players, send) ->
  boss =
    x: 400
    y: 300
    vx: 4
    vy: 4
    hp: 60
    radius: 50
    color: 'white'
  boss.maxhp = boss.hp

  nextAttack = 100

  send {boss}

  update: ->
    boss.x += boss.vx
    boss.y += boss.vy
    unless 0 < boss.x-boss.radius and boss.x+boss.radius < 1024
      boss.vx = -boss.vx
    unless 0 < boss.y-boss.radius and boss.y+boss.radius < 768
      boss.vy = -boss.vy

    nextAttack--
    if nextAttack == 30
      boss.color = 'yellow'
    if nextAttack == 2
      boss.color = 'red'
      boss.radius += 100
      for name,p of players
        if p.alive and within p, boss, boss.radius
          p.alive = false
          send {name, alive:false}

    if nextAttack == 0
      boss.color = 'white'
      boss.radius -= 100
      nextAttack = 100

    send {boss}

  attackAt: (p) ->
    if within p, boss, boss.radius
      boss.hp--
