
_state_limits = {
    velocity={10, 20, 30, 40}
}

_control_limits = {
    acceleration={5, 10, 15, 20},
    friction={0.0, 0.05, 0.1, 0.2},
    angular_velocity={0.25, 0.5, 0.75, 1.0}
}

miner_limits = {
    state={
        velocity=1,
    },
    controls={
        acceleration=1,
        friction=1,
        angular_velocity=1
    }
}

player_limits = {
    state={
        velocity=1,
    },
    controls={
        acceleration=1,
        friction=1,
        angular_velocity=1
    }
}

-- a list of targets for miners to cycle between
miner_targets = {}

-- state given by create_state
-- control takes the form {angular_velocity, acceleration, friction}
function update_state(state, control, limits, dt)
    if limits == nil then
        limits = {q=nil, q_dot=nil, q_ddot=nil}
    end

    -- q.x, q.y, q.d based directly off of q_dot.x, q_dot.y, q_dot.d
    state.q.x += state.q_dot.x * dt
    state.q.y += state.q_dot.y * dt
    state.q.d += state.q_dot.d * dt

    -- q_dot.x, q_dot.y based off of q_ddot
    state.q_dot.x += state.q_ddot.x * dt
    state.q_dot.y += state.q_ddot.y * dt
    -- q_dot.d based off of control and angular momentum
    state.q_dot.d = control.angular_velocity
    
    if limits.q_dot != nil then
        state.q_dot.x = mid(-limits.q_dot.x, state.q_dot.x, limits.q_dot.x)
        state.q_dot.y = mid(-limits.q_dot.y, state.q_dot.y, limits.q_dot.y)
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

      if dx > 0 and abs(dy) < target_threshold then
        e.control.acceleration = 100.0
      else
        e.control.acceleration = 0
      end

      e.limits = get_limits_from_settings(miner_limits)
      e.control.angular_velocity = mid(e.control.angular_velocity, e.limits.control.angular_velocity, -e.limits.control.angular_velocity)
      e.control.acceleration = mid(e.control.acceleration, e.limits.control.acceleration, -e.limits.control.acceleration)
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
