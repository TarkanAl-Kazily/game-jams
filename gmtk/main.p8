pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- Space Clicker v0_3
-- Tarkan Al-Kazily

_delta_t = 1.0 / 60.0
time = 0.0
score = 0
entities = {}

function create_entity(x, y)
  local result = {}
  result.pos = {x=x, y=y}
  result.vel = {cur=0.0, max=20.0, friction=1.0}
  result.acc = {cur=0.0, max=4.0, timer=0, friction=6.0}
  result.dir = {cur=0.0} -- starts facing positive x
  result.dir_vel = {cur=0.0, max=0.25, friction=2.0}
  result.dir_acc = {cur=0.0, max=1.0, timer=0, friction=2.0}
  result.friction = 1.0
  result.zone = nil
  return result
end

function create_zone(x, y, r, p)
  local result = create_entity(x, y)
  result.zone = {}
  result.zone.radius = r
  result.zone.color = 3
  result.zone.points = {val=p, timer=0, reset=1}
  return result
end

function _init()
  player = create_entity(5, 5)
  add(entities, player)
  earth = create_zone(64, 64, 30, 1)
  add(entities, earth)
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
  foreach(entities, draw_zone)

  print("[ score : "..score.." ]", 2)
  -- debug
  if _debug then
    print("pos ".. player.pos.x ..", "..player.pos.y)
    print("vel ".. player.vel.cur)
    print("acc ".. player.acc.cur)
    print("dir ".. player.dir.cur)
    print("dir_vel ".. player.dir_vel.cur)
    print("dir_acc ".. player.dir_acc.cur)
  end

  -- draw player
  --pset(player.pos.x, player.pos.y, 8)
  draw_player()
end

function draw_zone(e)
  if e.zone != nil then
    circfill(e.pos.x, e.pos.y, e.zone.radius, e.zone.color)
  end
end

-- update player
-- enables forward, left, and right
function update_player()
  if btn(0) then
    player.dir_acc.cur = player.dir_acc.max
    player.dir_acc.timer = 30
  end

  if btn(1) then
    player.dir_acc.cur = -player.dir_acc.max
    player.dir_acc.timer = 30
  end

  if btn(2) then
    player.acc.cur = player.acc.max
    player.acc.timer = 30
  end

  if btn(4) then
    foreach(entities, player_interact)
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
  e.dir.cur = (e.dir.cur + _delta_t * e.dir_vel.cur) % 1.0

  if abs(e.dir_acc.cur) > 0 then
    e.dir_vel.cur = mid(-e.dir_vel.max, e.dir_vel.cur + e.dir_acc.cur * _delta_t, e.dir_vel.max)
  else
    local sign = 1
    if e.dir_vel.cur < 0 then
      sign = -1
    end
    e.dir_vel.cur = mid(0.0, e.dir_vel.cur + e.dir_vel.friction * _delta_t * -sign, e.dir_vel.cur)
  end

  e.dir_acc.timer = max(0, e.dir_acc.timer - 1)
  if e.dir_acc.timer == 0 then
    e.dir_acc.cur = 0
  end

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

  if e.zone != nil then
    update_zone(e.zone)
  end
end

function update_zone(zone)
  if not btn(4) then
    zone.points.timer = max(0, zone.points.timer - 1)
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

-- Player interacts with the given zone
function player_interact(e)
  if e.zone == nil then 
    return
  end

  if distance_squared(player.pos, e.pos) > e.zone.radius * e.zone.radius then
    return
  end

  if e.zone.points.timer == 0 then
    e.zone.points.timer = e.zone.points.reset
    score += e.zone.points.val
  end
end

function distance_squared(p1, p2)
  local dx, dy = p1.x - p2.x, p1.y - p2.y
  return dx * dx + dy * dy
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
