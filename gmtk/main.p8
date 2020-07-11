pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- space clicker v0_11
-- tarkan al-kazily

#include objects.lua
#include controls.lua
#include draw.lua

_delta_t = 1.0 / 60.0
time = 0.0
score = 0
miner_count = 0
entities = {}
player_camera = {type="meta", state={q={x=64, y=64}}, radius=1}
camera_pos = {x=0, y=0}
world_bounds = {min={x=-128, y=-128}, max={x=255, y=255}}
background = nil
zones = nil
seed_background = 42
seed_zones = 48

player_mode = "manager"

function _init()
  background = generate_background()
  entities = generate_zones()
  miner = new_miner()
  add(entities, miner)
end

function _update60()
  time += _delta_t
  update_player()
  update_entities()
end

function control_camera()
  if btn(0) then
    player_camera.state.q.x -= 1
  end
  if btn(1) then
    player_camera.state.q.x += 1
  end
  if btn(2) then
    player_camera.state.q.y -= 1
  end
  if btn(3) then
    player_camera.state.q.y += 1
  end

  player_camera.state.q.x = mid(world_bounds.min.x, player_camera.state.q.x, world_bounds.max.x - 1)
  player_camera.state.q.y = mid(world_bounds.min.y, player_camera.state.q.y, world_bounds.max.y - 1)

  camera_pos.x = mid(world_bounds.min.x, player_camera.state.q.x - 64, world_bounds.max.x - 128)
  camera_pos.y = mid(world_bounds.min.y, player_camera.state.q.y - 64, world_bounds.max.y - 128)
end

function _draw()
  cls()

  draw_background()

  -- the cookie
  foreach(entities, draw_entity)
  camera(camera_pos.x, camera_pos.y)

  if player_mode == "manager" then
    draw_miner_path()
  end


  msg = "ore : "..flr(score)
  rect(camera_pos.x, camera_pos.y, camera_pos.x + 6 + 4 * #msg, camera_pos.y + 10, 1)
  print(msg, camera_pos.x + 3, camera_pos.y+ 3, 2)


  if player_mode == "manager" then
    line(player_camera.state.q.x - 4, player_camera.state.q.y, player_camera.state.q.x + 4, player_camera.state.q.y, 8)
    line(player_camera.state.q.x, player_camera.state.q.y - 4, player_camera.state.q.x, player_camera.state.q.y + 4, 8)
  end
  line(-128, -128, -128, 254, 1)
  line(254, 254)
  line(254, -128)
  line(-128, -128)
end

-->8
-- update code

-- moves the camera to try and center the player
function update_camera()
  local dx, dy = player.state.q.x - camera_pos.x, player.state.q.y - camera_pos.y
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
  update_state(e.state, e.control, e.limits, _delta_t)
  if (e.state.q.x < world_bounds.min.x) or (e.state.q.y < world_bounds.min.y) then
    del(entities, e)
  end
  if (e.state.q.x > world_bounds.max.x) or (e.state.q.y > world_bounds.max.y) then
    del(entities, e)
  end

  if e.type == "miner" then
    update_miner_control(e)
  end

  if e.type == "zone" then
    update_zone(e)
  end

  if e.type == "player" or e.type == "miner" then
    update_points(e)
  end
end


function update_zone(zone)
  zone.point = min(zone.point_cap, zone.point + zone.point_growth * _delta_t)
end

function update_points(ship)
  for i=1,#entities do
    e = entities[i]
    if (e.type == "zone") and overlap(e, ship) then
      local pts = flr(e.point)
      score += pts
      e.point -= pts
    end
  end
end

-->8
-- player code

function update_player()
  if player_mode == "ship" then
    update_player_control()
    update_camera()
    if btnp(5) then
      switch_from_ship()
      player_mode = "manager"
    end
  else
    control_camera()
    if btnp(5) then
      local affected_miner_path = modify_miner_path()
      if not affected_miner_path and switch_to_ship() then
        player_mode = "ship"
      end
    end
  end

  if btnp(4) then
    if score > 100 then
      score -= 100
      add(entities, new_miner())
    end
  end
end

-- update player
-- enables forward, left, and right
function update_player_control()
  if btn(0) then
    player.control.angular_velocity = 10.0
  end

  if btn(1) then
    player.control.angular_velocity = -10.0
  end

  if not (btn(0) or btn(1)) then
    player.control.angular_velocity = 0.0
  end

  if btn(2) then
    player.control.acceleration = 100.0
  else
    player.control.acceleration = 0.0
  end

  player.limits = get_limits_from_settings(player_limits)
  player.control.angular_velocity = mid(player.control.angular_velocity, player.limits.control.angular_velocity, -player.limits.control.angular_velocity)
  player.control.acceleration = mid(player.control.acceleration, player.limits.control.acceleration, -player.limits.control.acceleration)
end

-->8
-- utils and math

-- special euclidean transformation on a point
-- rotated first, then translated
function se2(point, state)
  local result, dx, dy, dd = {x=0, y=0}, state.x, state.y, state.d
  result.x = point.x * cos(dd) - point.y * sin(dd)
  result.y = point.x * sin(dd) + point.y * cos(dd)
  result.x += dx
  result.y += dy
  return result
end

function overlap(e1, e2)
  local dx, dy = e1.state.q.x - e2.state.q.x, e1.state.q.y - e2.state.q.y
  local sum_radius = e1.radius + e2.radius
  if abs(dx) > sum_radius or abs(dy) > sum_radius then
    return false
  end
  local dist = dx * dx + dy * dy
  return dist < sum_radius * sum_radius
end

function distance_squared(p1, p2)
  local dx, dy = p1.x - p2.x, p1.y - p2.y
  if (dx * dx + dy * dy) < 0 then
    return 10000.0
  end
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
