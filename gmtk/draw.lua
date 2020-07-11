-- The drawing code

-- draws the starry background. should be first in draw loop
function draw_background()
  foreach(background, draw_star)
end

-- draws the starry background
function draw_star(s)
  if s.t > 2 then
    line(s.x-1,s.y, s.x+1, s.y, s.c)
    line(s.x,s.y-1, s.x, s.y+1, s.c)
  else
    pset(s.x, s.y, s.c)
  end
end

-- draws circular zones (planets)
function draw_zone(z)
  local posx, posy = mid(z.state.q.x, camera_pos.x - z.radius, camera_pos.x + z.radius + 127), mid(z.state.q.y, camera_pos.y - z.radius, camera_pos.y + z.radius + 127)
  if posx != z.state.q.x or posy != z.state.q.y then
      return
  end
  circfill(z.state.q.x, z.state.q.y, z.radius, z.color)
  local dots, r, start, delta = flr(z.point), z.radius + 2, (time / 30 + z.state.q.x / 64.0) % 1.0, 0.7321
  for i=1, dots do
    pset(z.state.q.x + (r + sin(i / dots)) * cos((i * delta + start) % 1.0), z.state.q.y + (r + sin(i / dots)) *sin((i * delta + start) % 1.0), (i % 2 == 0) and 4 or 5)
  end
end

-- draws a little ship
function draw_ship(state_q, c, thrust)
  local p1, p2, p3, p4 = {x=3, y=0}, {x=-2, y=-2}, {x=-1, y=0}, {x=-2, y=2}

  p1 = se2(p1, state_q)
  p2 = se2(p2, state_q)
  p3 = se2(p3, state_q)
  p4 = se2(p4, state_q)

  draw_polygon({p1, p2, p3, p4}, c)

  if thrust then
    p1, p2, p3 = {x=-4, y=0}, {x=-2, y=1}, {x=-2, y=-1}
    p1 = se2(p1, state_q)
    p2 = se2(p2, state_q)
    p3 = se2(p3, state_q)
    draw_polygon({p1, p2, p3}, 7)
  end
end

-- dispatches the correct draw function
function draw_entity(e)
  if e.type == "player" then
    draw_ship(e.state.q, 8, e.control.acceleration > 0)
  elseif e.type == "miner" then
    draw_ship(e.state.q, 14, e.control.acceleration > 0)
    --print(e.current_target, e.state.q.x + 10, e.state.q.y, 7)
  elseif e.type == "zone" then
    draw_zone(e)
  end
end

function draw_miner_path()
    if #miner_targets < 1 then
        return
    end

    local tx, ty = miner_targets[1].state.q.x, miner_targets[1].state.q.y
    -- draw the x in yellow
    line(tx-1, ty-1, tx+1, ty+1, 10)
    line(tx-1, ty+1, tx+1, ty-1, 10)
    -- start the line in tan
    line(tx, ty, tx, ty, 15)
    for i = 2, #miner_targets do
        tx, ty = miner_targets[i].state.q.x, miner_targets[i].state.q.y
        -- draw the line in tan
        line(tx, ty)

        -- draw the x in yellow
        line(tx-1, ty-1, tx+1, ty+1, 10)
        line(tx-1, ty+1, tx+1, ty-1, 10)
        line(tx, ty, tx, ty, 15)
    end
    tx, ty = miner_targets[1].state.q.x, miner_targets[1].state.q.y
    line(tx, ty)
end

function draw_menu()
    local top_x, top_y = camera_pos.x, camera_pos.y
    local values = {miner_settings.max_velocity, miner_settings.max_acceleration, miner_settings.max_angular_velocity, miner_settings.kp_1, miner_settings.kd_1, miner_settings.kp_2, miner_settings.kd_2}
    local max_values = {upgrade_maximums.max_velocity, upgrade_maximums.max_acceleration, upgrade_maximums.max_angular_velocity, upgrade_maximums.kp_1, upgrade_maximums.kd_1, upgrade_maximums.kp_2, upgrade_maximums.kd_2}
    msg = "ore: "..flr(score)
    rect(top_x, top_y, top_x + 6 + 4 * #msg, top_y + 10, 1)
    print(msg, top_x + 3, top_y + 3, 8)
    
    msg = "ships: "..miner_count
    rect(top_x + 64, top_y, top_x + 70 + 4 * #msg, top_y + 10, 1)
    print(msg, top_x + 67, top_y + 3, 8)

    msg = "ship cost: "..ship_cost
    print(msg, top_x + 3, top_y + 20, 8)

    msg = "buy new ship"
    print(msg, top_x + 125 - 4 * #msg, top_y + 20, player_menu.menu_item == 0 and 10 or 8)

    top_y += 35
    local height = 13
    for i = 1, 7 do
        rectfill(top_x, top_y, top_x + 127 * values[i] / max_values[i], top_y + height, 11)
        rect(top_x, top_y, top_x + 127, top_y + height, 1)
        print(player_menu.entries[i].." "..values[i], top_x + 3, top_y + 3, player_menu.menu_item == i and 10 or 8)
        if i+1 <= #upgrade_costs then
            print(upgrade_costs[i+1], top_x + 125 - 4 * #tostr(upgrade_costs[i+1]), top_y + 3, player_menu.menu_item == i and 10 or 8)
        end
        top_y += height
    end
end
