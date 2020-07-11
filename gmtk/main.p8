pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- space controller v1_2d
-- tarkan al-kazily

#include objects.lua
#include controls.lua
#include draw.lua

_delta_t = 1.0 / 60.0
time = 0.0
score = 0
miner_count = 1
ship_cost = 100
entities = {}
player_camera = {type="meta", state={q={x=64, y=64}}, radius=1}
player_menu = {entries={"max speed", "max thrust", "max turning", "Kp dx", "Kd dx", "Kp dy", "Kd dy"}, menu_item=0}
camera_pos = {x=0, y=0}
world_bounds = {min={x=-128, y=-128}, max={x=255, y=255}}
background = nil
zones = nil
seed_background = 42
seed_zones = 48

upgrade_costs = {0, 100, 100, 100}

-- valid modes: ship, manager, menu
player_mode = "manager"

function _init()
  last_time_pts_sfx = time
  background = generate_background()
  entities = generate_zones()
  miner = new_miner()
  miner.state.q = {x=50, y=50, d=0}
  add(entities, miner)
end

function _update60()
  update_player()
  update_ship_cost()
  if player_mode != "menu" then
    time += _delta_t
    update_entities()
  end
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
  camera(camera_pos.x, camera_pos.y)
  if player_mode == "menu" then
    draw_menu()
  else

    -- the cookie
    for i=1,#entities do
      local e = entities[i]
      if e.type == "zone" then
        draw_entity(e)
      end
    end

    if player_mode == "manager" or player_mode == "ship" then
      draw_miner_path()
    end

    for i=1,#entities do
      local e = entities[i]
      if e.type != "zone" then
        draw_entity(e)
      end
    end

    -- score box
    msg = "ore: "..flr(score)
    rectfill(camera_pos.x, camera_pos.y, camera_pos.x + 6 + 4 * #msg, camera_pos.y + 10, 0)
    rect(camera_pos.x, camera_pos.y, camera_pos.x + 6 + 4 * #msg, camera_pos.y + 10, 1)
    print(msg, camera_pos.x + 3, camera_pos.y+ 3, 8)

    -- timer box
    local m, s = flr(time / 60), flr(time % 60)
    msg = m..":"..s
    if s < 10 then
      msg = m..":0"..s
    end
    rectfill(camera_pos.x + 127, camera_pos.y, camera_pos.x + 124 - 4 * #msg, camera_pos.y + 10, 0)
    rect(camera_pos.x + 127, camera_pos.y, camera_pos.x + 124 - 4 * #msg, camera_pos.y + 10, 1)
    print(msg, camera_pos.x + 127 - 4 * #msg, camera_pos.y+ 3, 8)



    if player_mode == "manager" then
      line(player_camera.state.q.x - 4, player_camera.state.q.y, player_camera.state.q.x + 4, player_camera.state.q.y, 8)
      line(player_camera.state.q.x, player_camera.state.q.y - 4, player_camera.state.q.x, player_camera.state.q.y + 4, 8)
    end
    line(-128, -128, -128, 254, 1)
    line(254, 254)
    line(254, -128)
    line(-128, -128)
  end
end

-->8
-- update code

-- moves the camera to try and center the player
function update_camera()
  local dx, dy = player.state.q.x - camera_pos.x, player.state.q.y - camera_pos.y
  if dx < 32 then
    camera_pos.x -= 2.0
  elseif dx > 95 then
    camera_pos.x += 2.0
  end

  if dy < 32 then
    camera_pos.y -= 1.0
  elseif dy > 95 then
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
    miner_count -= 1
    del(entities, e)
  elseif (e.state.q.x > world_bounds.max.x) or (e.state.q.y > world_bounds.max.y) then
    miner_count -= 1
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
  for i=1,#entities do
    local e = entities[i]
    if (e.type == "miner" or e.type == "player") and overlap(e, zone) then
      return
    end
  end
  zone.point = min(zone.point_cap, zone.point + zone.point_growth * _delta_t)
end

function update_points(ship)
  for i=1,#entities do
    e = entities[i]
    if (e.type == "zone") and overlap(e, ship) then
      local pts = flr(e.point)
      if pts > 0 and time - last_time_pts_sfx > 0.1 then
        sfx(0)
        last_time_pts_sfx = time
      end
      score += min(pts, 1)
      e.point -= min(pts, 1)
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
      player_camera.state.q.x = camera_pos.x + 64
      player_camera.state.q.y = camera_pos.y + 64
      switch_from_ship()
      player_mode = "manager"
    end
  elseif player_mode == "manager" then
    control_camera()
    if btnp(5) then
      if switch_to_ship() then
        player_mode = "ship"
      else
        modify_miner_path()
      end
    elseif btnp(4) then
      player_mode = "menu"
    end
  elseif player_mode == "menu" then
    update_player_menu()
    if btnp(4) then
      player_mode = "manager"
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

  if btn(3) then
    player.control.friction = 100.0
  else
    player.control.friction = 0.0
  end

  player.control.angular_velocity = mid(player.control.angular_velocity, miner_settings.max_angular_velocity, -miner_settings.max_angular_velocity)
  player.control.acceleration = mid(player.control.acceleration, miner_settings.max_acceleration, -miner_settings.max_acceleration)
  player.control.friction = mid(player.control.friction, miner_settings.max_friction, -miner_settings.max_friction)
end

function update_ship_cost()
  ship_cost = 75 + miner_count * 25
  if miner_count == 0 then
    ship_cost = 0
  end
  upgrade_costs[1] = ship_cost
end

function update_player_menu()
  local values = {miner_settings.max_velocity, miner_settings.max_acceleration, miner_settings.max_angular_velocity, miner_settings.kp_1, miner_settings.kd_1, miner_settings.kp_2, miner_settings.kd_2}
  local max_values = {upgrade_maximums.max_velocity, upgrade_maximums.max_acceleration, upgrade_maximums.max_angular_velocity, upgrade_maximums.kp_1, upgrade_maximums.kd_1, upgrade_maximums.kp_2, upgrade_maximums.kd_2}
  if btnp(2) then
    player_menu.menu_item -= 1
  end

  if btnp(3) then
    player_menu.menu_item += 1
  end
  player_menu.menu_item = mid(0, player_menu.menu_item, #player_menu.entries)


  if btnp(5) then
    if player_menu.menu_item < #upgrade_costs then
      if score > upgrade_costs[player_menu.menu_item+1] then
        score -= upgrade_costs[player_menu.menu_item+1]
        if player_menu.menu_item == 0 then
          add(entities, new_miner())
          miner_count += 1
        else
          max_values[player_menu.menu_item] += upgrade_amounts[player_menu.menu_item]
          upgrade_costs[player_menu.menu_item+1] += 25
        end
      end
    end
  end

  if player_menu.menu_item > 0 and btn(0) then
    values[player_menu.menu_item] -= 0.01 * max_values[player_menu.menu_item]
  end

  if player_menu.menu_item > 0 and btn(1) then
    values[player_menu.menu_item] += 0.01 * max_values[player_menu.menu_item]
  end

  miner_settings.max_velocity = mid(0, values[1], max_values[1])
  miner_settings.max_acceleration = mid(0, values[2], max_values[2])
  miner_settings.max_angular_velocity = mid(0, values[3], max_values[3])
  miner_settings.kp_1 = mid(0, values[4], max_values[4])
  miner_settings.kd_1 = mid(0, values[5], max_values[5])
  miner_settings.kp_2 = mid(0, values[6], max_values[6])
  miner_settings.kd_2 = mid(0, values[7], max_values[7])

  upgrade_maximums.max_velocity = max_values[1]
  upgrade_maximums.max_acceleration = max_values[2]
  upgrade_maximums.max_angular_velocity = max_values[3]
  upgrade_maximums.kp_1 = max_values[4]
  upgrade_maximums.kd_1 = max_values[5]
  upgrade_maximums.kp_1 = max_values[6]
  upgrade_maximums.kd_2 = max_values[7]
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
__label__
11111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000100000000000000000000000000000000009000000000000000000000000000000000000000000000000000000
10002202220222000000000222020002220000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10020202020200002000000202020002000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10020202200220000000000222022202220000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10020202020200002000000202020200020000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10022002020222000000000222022202220000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaa0000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000e777000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000e0e77000000000000000000000000000000000000000000000000000000000000000
00000000000000700000000000000000000000000000000000000000000e0ee70000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000eee0000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000040040000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000
00000000000000000000050005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000044504000540000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000
00000000000000000000000555554050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000
00000000000000000005055555555000500000000000000000000000000000000055555000000000000000000000000000000000000000000000000000000000
00000000000000000004055555555540400000000000000000000000000000000555555500000000000000000000000000000000000000000000000000000000
07000000000000000005555555555555007000000000000000000000000004005555555550000000000000000000000000000000000000000000000000000000
000000000000000005005555a5a55554000000000000000000000000000000055555555555000000000000000000000000000000000000000000000000000000
0000000000000000004055555ffffffffffffffffffffff00000000000000005555a5a5555000000000000000000000000000000000000000000000000000000
000000000000000000455555a5aff555000000000000000ffffffffffffffffffffff55555004000000000000000000000000000000000000000000000000000
00000000000000000050555555555ff040000000000000000000000000000005555a5f5555000000000000000000000000000000000000000000000000000000
0000000000000000000405555555550ff0000000000000000000000000000005555555f5550a0000000000000000000000000000000000000000000000000000
000000000000000000000055555550500fff0000000000000000000000000000555555f550000000000000000000000000000000000000000000000000000000
000000000000000000045405555550040000ff000000000000000000000000000555555f00000000000000000000000000000000000000000000000000000000
00000009000000000000000400400450000000ff00000000000000000000000000555550f0000000000000000000000000000000000000000000000000000000
0000000000000000000004500055400000000000fff000000000000000000000000005000f000000000000000000000000000000000000000000000000000000
0000000000000000000000000400000000000000000ff0000000000000000000805000000f000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000ff000000000000000008000000000f00000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000ff00000000000000080000000000f0000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000fff000000000000800000000000f00000000000000000000000000000000000000000a000000000
0000000000000000000000000000000000000000000000000000ff00000088888888800000000f00000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000ff000000008000000000000f00000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000fff0000080000000000000f0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000ff000800000000000000f000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000ff08000000000000000f00000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000ff000000000000000f00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000fff0000000000000f0000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000ff000000000000f000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000ff00000000000f00004000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000fff000000000f000a054000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000f4050400005000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000ff000000f055555404000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000ff00505f55555504050000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000fff055f5555550000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff5f5555555500000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000005055fff5a5555045000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000405555ff55555000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000055555a5a5555500000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555555004000000000000000000000000000000
40000000000000000000000000000000000000000000000000000000000000000000000000000000005045555555550005000000000000000000000000000000
40000000000000000000000000000000000000000000000000000000000000000000000000000000000050555555500500000000000000000000000000000000
00550000000000000000000000000405000000000000000000000000000000000000000000000000000040455555005400000000000000000000000000000000
05000000000000000000000000050000040504000000000000000000000000000000000000000000000050004004054000000000000000000000000000000000
33004440000000000000000050400405000000050000000000000000000000000000000000000000000000450050000000000000000000000000000000000000
3330400000000000000000400040ddddddd040500000000000000000000000000000000000000000000000000400040000000000000000000000000000000000
3333000000000000000000405ddddddddddddd004050000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333055500000000004050ddddddddddddddddd0050400000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333330000000000000000ddddddddddddddddddd004000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333333300004000005004ddddddddddddddddddddd00050000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333044000000005ddddddddddddddddddddddd0500000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333330000000440ddddddddddddddddddddddddd004000000000000000000000000000000000000000000000000000000000000000000000000000000000
333333333300500000ddddddddddddddddddddddddddd05500000000000000000000000000000000000000000000000000000000000000000000000000000000
333333333305050050ddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333000040ddddddddddddddddddddddddddddd4040000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333304004ddddddddddddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333304440ddddddddddddddddddddddddddddd0550000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333300005dddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333333333050ddddddddddddddddddddddddddddddd004000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333330505dddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333333333355ddddddddddddddddddddddddddddddd055000000000000000000000000000000700000000000000000000000000000000000000000000000
3333333333333300ddddddddddddddddddddddddddddddd400000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333444dddddddddddddddddddddddddddddd004000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333333333300d4ddddddddddddddddddddddddddddd050000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333305ddddddddddddddddddddddddddddd0050000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333300ddddddddddddddddddddddddddddd0400000000000000000000000000000000000000000000000000000000000000000000000000000000
333333333333333505dddddddddddddddddddddddddddd0040000000000000000000000000000000000000000000000000000000000000000000000000000000
333333333333333055ddddddddddddddddddddddddddd05000000000000000000000000000000000000000000000000000000000000000000000000000000000
333333333333333000ddddddddddddddddddddddddddd40050000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333333333330404ddddddddddddddddddddddddd004000000000000000000000000007000000000000000000000000000000000000000000000000000000
33333333333333300400ddddddddddddddddddddddd00500000000000000000000000000000000000000000000000a0000000000000000000000000000000000
333333333333333004550ddddddddddddddddddddd04000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333333333335000040ddddddddddddddddddd050400000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333305000005ddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333333333330550050040ddddddddddddd004005000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333333333300000000405000ddddddd504050400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333040000000050405040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333040000000000050005040504000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333004000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333330550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333330050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333300050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333304000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
0106000011556115562e5562e5562b556215061d50600506015062150623506005060050600506005060050600506005060050600506005060050600506005060050600506005060050600506000000000000000
010100000d6100d6100d6100d6100d6101d6001e60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
