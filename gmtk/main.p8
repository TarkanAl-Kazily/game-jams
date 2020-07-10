pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- Space Clicker v0_5
-- Tarkan Al-Kazily

_delta_t = 1.0 / 60.0
time = 0.0
score = 0
entities = {}
camera_pos = {x=0, y=0}
world_bounds = {min={x=-128, y=-128}, max={x=255, y=255}}
background = nil
seed_background = 42

function create_entity(x, y)
  local result = {}
  result.pos = {x=x, y=y}
  result.vel = {cur={x=0, y=0}, max=30.0, friction=1.0}
  result.acc = {cur=0.0, max=20.0, timer=0, friction=20.0}
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
  result.zone.timer = {cur=0, reset=1}
  result.zone.points = p
  result.zone.action = add_points
  return result
end

function create_miner_zone(x, y, r, cost)
  local result = create_zone(x, y, r, 0)
  result.zone.color = 5
  result.zone.action = buy_miner
end

function _init()
  background = generate_background()
  player = create_entity(5, 5)
  add(entities, player)
  earth = create_zone(64, 64, 30, 1)
  add(entities, earth)
end

function _update60()
  time += _delta_t
  update_player()
  update_entities()
  update_camera()
end

function _draw()
  cls()
  line(-128, -128, -128, 255, 1)
  line(255, 255)
  line(255, -128)
  line(-128, -128)

  draw_background()

  camera(camera_pos.x, camera_pos.y)

  -- the cookie
  foreach(entities, draw_zone)

  print("[ score : "..score.." ]", camera_pos.x, camera_pos.y, 2)
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

-->8
-- update code

-- moves the camera to try and center the player
function update_camera()
  local dx, dy = player.pos.x - camera_pos.x, player.pos.y - camera_pos.y
  if dx < 16 then
    camera_pos.x -= 2.0
  elseif dx > 112 then
    camera_pos.x += 2.0
  end

  if dy < 16 then
    camera_pos.y -= 1.0
  elseif dy > 112 then
    camera_pos.y += 1.0
  end

  camera_pos.x = mid(world_bounds.min.x, camera_pos.x, world_bounds.max.x - 128)
  camera_pos.y = mid(world_bounds.min.y, camera_pos.y, world_bounds.max.y - 128)
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
    e.dir_vel.cur = mid(0.0, e.dir_vel.cur - sign(e.dir_vel.cur) * e.dir_vel.friction * _delta_t, e.dir_vel.cur)
  end

  e.dir_acc.timer = max(0, e.dir_acc.timer - 1)
  if e.dir_acc.timer == 0 then
    e.dir_acc.cur = 0
  end

  e.pos.x, e.pos.y = e.pos.x + _delta_t * e.vel.cur.x, e.pos.y + _delta_t * e.vel.cur.y
  if e.acc.cur > 0 then
    e.vel.cur.x = mid(-e.vel.max, e.vel.cur.x + _delta_t * e.acc.cur * cos(e.dir.cur), e.vel.max)
    e.vel.cur.y = mid(-e.vel.max, e.vel.cur.y + _delta_t * e.acc.cur * sin(e.dir.cur), e.vel.max)
  else
    e.vel.cur.x = mid(0, e.vel.cur.x - sign(e.vel.cur.x) * _delta_t * e.vel.friction, e.vel.cur.x)
    e.vel.cur.y = mid(0, e.vel.cur.y - sign(e.vel.cur.y) * _delta_t * e.vel.friction, e.vel.cur.y)
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
    zone.timer.cur = max(0, zone.timer.cur - 1)
  end
end

function draw_zone(e)
  if e.zone != nil then
    circfill(e.pos.x, e.pos.y, e.zone.radius, e.zone.color)
  end
end

-->8
-- player code

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
  else
    player.acc.cur = 0
  end

  if btn(4) then
    foreach(entities, player_interact)
  end
end

-- Player interacts with the given zone
function player_interact(e)
  if e.zone == nil then 
    return
  end

  if distance_squared(player.pos, e.pos) > e.zone.radius * e.zone.radius then
    return
  end

  if e.zone.timer.cur == 0 then
    e.zone.timer.cur = e.zone.timer.reset
    e.zone.action(e)
  end

end

function add_points(e)
  score += e.zone.points
end


-->8
-- drawing code

-- creates a starry background. should be called once
function generate_background()
  srand(seed_background)
  local result = {}
  for i=1,128 do
    local star = {x=rnd_between(world_bounds.min.x, world_bounds.max.x), y=rnd_between(world_bounds.min.y, world_bounds.max.y), c=flr(rnd(3)), t=flr(rnd(4))}
    if star.c == 0 then
      star.c = 7
    elseif star.c == 1 then
      star.c = 9
    else
      star.c = 10
    end
    add(result, star)
  end
  return result
end

-- draws the starry background. should be first in draw loop
function draw_background()
  foreach(background, draw_star)
end

function draw_star(s)
  if s.t > 2 then
    line(s.x-1,s.y, s.x+1, s.y, s.c)
    line(s.x,s.y-1, s.x, s.y+1, s.c)
  else
    pset(s.x, s.y, s.c)
  end
end

-- draws a little ship
function draw_player()
  local p1, p2, p3, p4 = {x=3, y=0}, {x=-2, y=-2}, {x=-1, y=0}, {x=-2, y=2}

  p1 = se2(p1, player.pos, player.dir.cur)
  p2 = se2(p2, player.pos, player.dir.cur)
  p3 = se2(p3, player.pos, player.dir.cur)
  p4 = se2(p4, player.pos, player.dir.cur)

  draw_polygon({p1, p2, p3, p4}, 8)

  if btn(2) then
    p1, p2, p3 = {x=-4, y=0}, {x=-2, y=1}, {x=-2, y=-1}
    p1 = se2(p1, player.pos, player.dir.cur)
    p2 = se2(p2, player.pos, player.dir.cur)
    p3 = se2(p3, player.pos, player.dir.cur)
    draw_polygon({p1, p2, p3}, 7)
  end
end

-->8
-- utils and math

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

function distance_squared(p1, p2)
  local dx, dy = p1.x - p2.x, p1.y - p2.y
  return dx * dx + dy * dy
end

function rnd_between(small, large)
  return rnd(large - small) + small
end

function sign(val)
  return (val < 0) and -1 or 1
end

function draw_polygon(points, c)
  line(points[1].x, points[1].y, points[2].x, points[2].y, c)
  for i=3, #points do
    line(points[i].x, points[i].y)
  end
  line(points[1].x, points[1].y)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
