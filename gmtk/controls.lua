miner_settings = {
    max_velocity = 30,
    max_acceleration=10,
    max_angular_velocity=0.25,
    kp_1=30.0,
    kd_1=3.0,
    kp_2=3.0,
    kd_2=5.0,
}

upgrade_maximums = {
    max_velocity = 30,
    max_acceleration=10,
    max_angular_velocity=0.25,
    kp_1=100.0,
    kd_1=50.0,
    kp_2=100.0,
    kd_2=50.0
}

upgrade_amounts = {
    5.0, 2.5, 0.125
}

-- a list of targets for miners to cycle between
miner_targets = {}

-- state given by create_state
-- control takes the form {angular_velocity, acceleration
function update_state(state, control, limits, dt)
    -- q.x, q.y, q.d based directly off of q_dot.x, q_dot.y, q_dot.d
    state.q.x += state.q_dot.x * dt
    state.q.y += state.q_dot.y * dt
    state.q.d += state.q_dot.d * dt

    -- q_dot.x, q_dot.y based off of q_ddot
    state.q_dot.x += state.q_ddot.x * dt
    state.q_dot.y += state.q_ddot.y * dt
    -- q_dot.d based off of control and angular momentum
    state.q_dot.d = (rnd(0.2) + rnd(0.2) + 0.8) * control.angular_velocity
    
    if limits != nil then
        local vel_dir = atan2(state.q_dot.x, state.q_dot.y)
        state.q_dot.x = mid(-limits.max_velocity * cos(vel_dir), state.q_dot.x, limits.max_velocity * cos(vel_dir))
        state.q_dot.y = mid(-limits.max_velocity * sin(vel_dir), state.q_dot.y, limits.max_velocity * sin(vel_dir))
    end

    -- q_ddot.x and q_ddot.y based off of control, q.d
    state.q_ddot.x = cos(state.q.d) * (rnd(0.3) + rnd(0.3) + 0.7) * control.acceleration
    state.q_ddot.y = sin(state.q.d) * (rnd(0.3) + rnd(0.3) + 0.7) * control.acceleration

    -- q_ddot.d unused
    state.q_ddot.d = 0

    if control.acceleration > 0 then
        sfx(1)
    end
end

function update_miner_control(e)
  if e.current_target > 0 and #miner_targets == 0 then
    e.control = create_control()
    return
  end

  if e.current_target > #miner_targets then
    e.current_target = 1
  end

  local target_zone = nil
  if e.current_target > 0 then
      target_zone = miner_targets[e.current_target]
  else
      target_zone = e.zero_target_zone
  end

  if overlap(e, target_zone) or out_of_bounds(target_zone) then
      if e.current_target == 0 then
        e.current_target = flr(rnd_between(1, #miner_targets + 1))
      else
        e.current_target = (e.current_target % #miner_targets) + 1
      end
      target_zone = miner_targets[e.current_target]
  end

  if target_zone == nil then
    e.current_target = flr(rnd_between(1, #miner_targets + 1))
    e.control = create_control()
    return
  end

  local dx, dy = target_zone.state.q.x - e.state.q.x, - target_zone.state.q.y + e.state.q.y
  local dir = atan2(dx, dy)
  local vx, vy = target_zone.state.q_dot.x - e.state.q_dot.x, target_zone.state.q_dot.y - e.state.q_dot.y
  dx, dy = cos(e.state.q.d) * dx - sin(e.state.q.d) * dy, sin(e.state.q.d) * dx + cos(e.state.q.d) * dy
  vx, vy = cos(dir) * vx - sin(dir) * vy, sin(dir) * vx + cos(dir) * vy
  --dx *= e.controls.kp.dx
  --dy *= e.controls.kp.dy
  dx = max(0, dx)

  e.control.angular_velocity = miner_settings.kp_2 * dy - miner_settings.kd_2 * vy
  e.control.acceleration = miner_settings.kp_1 * dx + miner_settings.kd_1 * vx

  e.control.angular_velocity = mid(e.control.angular_velocity, miner_settings.max_angular_velocity, -miner_settings.max_angular_velocity)
  e.control.acceleration = mid(e.control.acceleration, miner_settings.max_acceleration, -miner_settings.max_acceleration)
end

function modify_miner_path()
    local zone = nil
    for i=1, #entities do
        local e = entities[i]
        if e.type == "zone" and overlap(e, player_camera) then
            if zone == nil or e.radius < zone.radius then
                zone = e
            end
        end
    end
    if zone == nil then
        return false
    end
    local removed = del(miner_targets, zone)
    if removed == nil then
        add(miner_targets, zone)
    end
    return true
end

function switch_to_ship()
    local ship = nil
    for i=1, #entities do
        local e = entities[i]
        if e.type == "miner" and overlap(e, player_camera) then
            ship = e
            break
        end
    end
    if ship == nil then
        return false
    end
    player = ship
    ship.type = "player"
    return true
end

function switch_from_ship()
    player.type = "miner"
    player = nil
end

function miners_scatter()
    picked_zones = {}
    for i=1,#entities do
        local e = entities[i]
        if e.type == "miner" then
            printh("Hi!")
            e.current_target = 0
            e.zero_target_zone = next_random_zone(picked_zones)
            add(picked_zones, e.zero_target_zone)
        end
    end
end

-- returns one zone at random in entities that is not in removed.
function next_random_zone(removed)
    local start = flr(rnd_between(1, #entities + 1))
    for i=0,#entities-1 do
        local e = entities[(start + i) % #entities + 1]
        if e.type == "zone" and not contains(removed, e) then
            return e
        end
    end
end

function contains(list, element)
    for i=1,#list do
        if list[i] == element then
            return true
        end
    end
    return false
end
