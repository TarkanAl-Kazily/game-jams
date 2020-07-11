
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
miner_targets = {
    {x=0, y=0},
    {x=64, y=64},
    {x=128, y=0}
}

function get_limits_from_settings(settings)
    local limits = {}
    limits.q_dot = {x=_state_limits.velocity[settings.state.velocity], y=_state_limits.velocity[settings.state.velocity], d=100}
    limits.control = {}
    limits.control.acceleration = _control_limits.acceleration[settings.controls.acceleration]
    limits.control.friction = _control_limits.friction[settings.controls.friction]
    limits.control.angular_velocity = _control_limits.angular_velocity[settings.controls.angular_velocity]
    return limits
end

function new_entity()
    local result = {}
    result.state = create_state(nil, nil, nil)
    result.control = create_control()
    result.limits = nil
    result.type = nil
    return result
end

function new_miner()
    local result = new_entity()
    result.limits = get_limits_from_settings(miner_limits)
    result.type = "miner"
    result.current_target = 1
    result.target_threshold = 25
    return result
end

function new_player()
    local result = new_entity()
    result.limits = get_limits_from_settings(player_limits)
    result.type = "player"
    return result
end

function create_state(q, q_dot, q_ddot)
    local result = {q=q, q_dot=q_dot, q_ddot=q_ddot}
    if result.q == nil then
        result.q = {x=0, y=0, d=0}
    end
    if result.q_dot == nil then
        result.q_dot = {x=0, y=0, d=0}
    end
    if result.q_ddot == nil then
        result.q_ddot = {x=0, y=0, d=0}
    end
    return result
end

function create_control()
    return {angular_velocity=0, acceleration=0, friction=0}
end

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
  local target = miner_targets[e.current_target]

  if distance_squared(e.state.q, target) < e.target_threshold * e.target_threshold then
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

      if dx > 0 and abs(dy) < e.target_threshold then
        e.control.acceleration = 100.0
      else
        e.control.acceleration = 0
      end

      e.limits = get_limits_from_settings(miner_limits)
      e.control.angular_velocity = mid(e.control.angular_velocity, e.limits.control.angular_velocity, -e.limits.control.angular_velocity)
      e.control.acceleration = mid(e.control.acceleration, e.limits.control.acceleration, -e.limits.control.acceleration)
  end
end
