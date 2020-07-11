miner_settings = {
    max_velocity = 10,
    max_acceleration=5,
    max_angular_velocity=0.25,
    max_friction=0.0,
    kp_1=0.25,
    kp_2=1.0
}

upgrade_maximums = {
    max_velocity = 20,
    max_acceleration=10,
    max_angular_velocity=2.0,
    max_friction=1.0,
    kp_1=1.0,
    kp_2=1.0
}

upgrade_amounts = {
    5.0, 2.5, 0.25, 0.1
}

-- a list of targets for miners to cycle between
miner_targets = {}

-- state given by create_state
-- control takes the form {angular_velocity, acceleration, friction}
function update_state(state, control, limits, dt)
    -- q.x, q.y, q.d based directly off of q_dot.x, q_dot.y, q_dot.d
    state.q.x += state.q_dot.x * dt
    state.q.y += state.q_dot.y * dt
    state.q.d += state.q_dot.d * dt

    -- q_dot.x, q_dot.y based off of q_ddot
    state.q_dot.x += state.q_ddot.x * dt
    state.q_dot.y += state.q_ddot.y * dt
    -- q_dot.d based off of control and angular momentum
    state.q_dot.d = control.angular_velocity
    
    if limits != nil then
        state.q_dot.x = mid(-limits.max_velocity * cos(state.q.d), state.q_dot.x, limits.max_velocity * cos(state.q.d))
        state.q_dot.y = mid(-limits.max_velocity * sin(state.q.d), state.q_dot.y, limits.max_velocity * sin(state.q.d))
    end

    -- q_ddot.x and q_ddot.y based off of control, q.d, and control friction
    state.q_ddot.x = cos(state.q.d) * control.acceleration - state.q_dot.x * control.friction
    state.q_ddot.y = sin(state.q.d) * control.acceleration - state.q_dot.y * control.friction

    -- q_ddot.d unused
    state.q_ddot.d = 0
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

  if distance_squared(e.state.q, target) < target_threshold * target_threshold then
    e.current_target = (e.current_target % #miner_targets) + 1
  else
      local dx, dy = target.x - e.state.q.x, - target.y + e.state.q.y
      dx, dy = cos(e.state.q.d) * dx - sin(e.state.q.d) * dy, sin(e.state.q.d) * dx + cos(e.state.q.d) * dy
      --dx *= e.controls.kp.dx
      --dy *= e.controls.kp.dy

      if (dx < 0) or abs(dy) > 0.0 then
        e.control.angular_velocity = sign(dy) * 10.0
      else
        e.control.angular_velocity = 0
      end

      if dx > 0 then
        e.control.acceleration = 100.0
      else
        e.control.acceleration = 0
      end

      e.control.angular_velocity = mid(e.control.angular_velocity, miner_settings.max_angular_velocity, -miner_settings.max_angular_velocity)
      e.control.acceleration = mid(e.control.acceleration, miner_settings.max_acceleration, -miner_settings.max_acceleration)
      e.control.friction = mid(e.control.friction, miner_settings.max_friction, -miner_settings.max_friction)
  end
end

function modify_miner_path()
    local zone = nil
    for i=1, #entities do
        local e = entities[i]
        if e.type == "zone" and overlap(e, player_camera) then
            zone = e
            break
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
