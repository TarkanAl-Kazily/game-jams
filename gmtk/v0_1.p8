pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

_delta_t = 1.0 / 60.0
time = 0.0
entities = {}

function create_entity()
  local result = {}
  result.pos = {x=20, y=20}
  result.acc = {cur=0.0, max=4.0, timer=0, friction=2.0}
  result.vel = {cur=0.0, max=10.0, friction=2.0}
  result.dir = {cur=0.0, rate=0.5} -- starts facing positive x
  result.friction = 1.0
  return result
end

function _init()
  player = create_entity()
  add(entities, player)
end

function _update60()
  time += _delta_t
  update_player()
  update_entities()
end

function _draw()
  cls()
  pset(0, 0, 12)
  pset(127, 0, 12)
  pset(127, 127, 12)
  pset(0, 127, 12)

  -- the cookie
  circfill(64, 64, 30, 15)

  -- debug
  print("pos ".. player.pos.x ..", "..player.pos.y)
  print("vel ".. player.vel.cur)
  print("acc ".. player.acc.cur)
  print("dir ".. player.dir.cur)

  -- draw player
  --pset(player.pos.x, player.pos.y, 8)
  draw_player()
end

-- update player
-- enables forward, left, and right
function update_player()
  if btnp(0) then
    player.dir.cur += player.dir.rate * _delta_t
  end

  if btnp(1) then
    player.dir.cur -= player.dir.rate * _delta_t
  end

  if btnp(2) then
    player.acc.cur = player.acc.max
    player.acc.timer = 30
  end
end

-- updates all entities
-- applies movement physics
function update_entities()
  foreach(entities, update_entity)
end

-- updates an entity
-- applies movement physics
function update_entity(e)
  e.dir.cur = e.dir.cur % 1.0
  e.pos.x, e.pos.y = e.pos.x + _delta_t * e.vel.cur * cos(e.dir.cur), e.pos.y + _delta_t * e.vel.cur * sin(e.dir.cur)
  if e.acc.cur > 0 then
    e.vel.cur = mid(0.0, e.vel.cur + _delta_t * e.acc.cur, e.vel.max)
  else
    e.vel.cur = mid(0.0, e.vel.cur - _delta_t * e.vel.friction, e.vel.max)
  end
  e.acc.timer = max(0, e.acc.timer - 1)
  if e.acc.timer == 0 then
    e.acc.cur = mid(0.0, e.acc.cur - _delta_t * e.acc.friction, e.acc.max)
  end
end

-- draws a little ship
function draw_player()
  local p1, p2, p3, p4 = {x=2, y=0}, {x=-2, y=-2}, {x=-0.75, y=0}, {x=-2, y=2}

  p1 = se2(p1, player.pos, player.dir.cur)
  p2 = se2(p2, player.pos, player.dir.cur)
  p3 = se2(p3, player.pos, player.dir.cur)
  p4 = se2(p4, player.pos, player.dir.cur)

  line(p1.x, p1.y, p2.x, p2.y, 8)
  line(p3.x, p3.y)
  line(p4.x, p4.y)
  line(p1.x, p1.y)
end

-- special euclidean transformation on a point
-- rotated first, then translated
function se2(point, translation, rotation)
  local result = {x=0, y=0}
  result.x = point.x * cos(rotation) - point.y * sin(rotation)
  result.y = point.x * sin(rotation) + point.y * cos(rotation)
  result.x += translation.x
  result.y += translation.y
  return result
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
