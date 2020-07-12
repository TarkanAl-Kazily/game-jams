miner_settings = {
    max_velocity = 10,
    max_acceleration=5,
    max_angular_velocity=0.25,
    kp_1=10,
    kp_2=10.0,
    kd_1=2.0,
    kd_2=2.0,
}

upgrade_maximums = {
    max_velocity = 10,
    max_acceleration=5,
    max_angular_velocity=0.25,
    kp_1=100.0,
    kp_2=100.0,
    kd_1=10.0,
    kd_2=10.0
}

upgrade_amounts = {
    5.0, 2.5, 0.25, 0.1
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
  if #miner_targets == 0 then
    e.control = create_control()
    return
  end

  if e.current_target > #miner_targets then
    e.current_target = 1
  end

  local target_zone = miner_targets[e.current_target]
  local target_threshold = target_zone.radius
  local target = target_zone.state.q

  if overlap(e, target_zone) then
    e.current_target = (e.current_target % #miner_targets) + 1
  end
  local dx, dy = target.x - e.state.q.x, - target.y + e.state.q.y
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
