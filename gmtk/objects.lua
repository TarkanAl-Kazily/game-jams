
function get_limits_from_settings(settings)
    local limits = {}
    limits.q_dot = {x=_state_limits.velocity[settings.state.velocity], y=_state_limits.velocity[settings.state.velocity], d=100}
    limits.control = {}
    limits.control.acceleration = _control_limits.acceleration[settings.controls.acceleration]
    limits.control.friction = _control_limits.friction[settings.controls.friction]
    limits.control.angular_velocity = _control_limits.angular_velocity[settings.controls.angular_velocity]
    return limits
end

-- creates the base entity type, with a state compatible for control
function new_entity()
    local result = {}
    result.state = create_state(nil, nil, nil)
    result.control = create_control()
    result.limits = nil
    result.type = nil
    result.radius = 3
    return result
end

-- creates a miner ship
function new_miner()
    local result = new_entity()
    result.limits = get_limits_from_settings(miner_limits)
    result.type = "miner"
    result.current_target = 1
    result.target_threshold = 25
    return result
end

-- creates a player ship
function new_player()
    local result = new_entity()
    result.limits = get_limits_from_settings(player_limits)
    result.type = "player"
    return result
end

-- Fills out a state
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

-- fills out a control
function create_control()
    return {angular_velocity=0, acceleration=0, friction=0}
end


-- Creates a zone type entity, which will add to the player's score
function new_zone()
  local result = new_entity()
  result.type = "zone"
  result.radius = 30
  result.color = 11
  result.point = 0
  result.point_growth = 1.0
  result.point_cap = 100
  return result
end

-- Creates multiple random zone type entities
function generate_zones()
  local result = {}
  for i=1, 32 do
    local zone = new_zone()
    zone.state.q = {x=rnd_between(world_bounds.min.x, world_bounds.max.x), y=rnd_between(world_bounds.min.y, world_bounds.max.y), d=0}
    size = flr(rnd(10))
    if size < 2 then
      -- large planet
      zone.radius = 30
      zone.color = 3
      zone.point_growth = 1.5
      zone.point_cap = 200
    elseif size < 5 then
      -- medium planet
      zone.radius = 15
      zone.color = 13
      zone.point_growth = 2.0
      zone.point_cap = 100
    else
      zone.radius = 5
      zone.color = 5
      zone.point_growth = 3.0
      zone.point_cap = 50
    end
    local add_zone = true
    for j=1, #result do
        if overlap(result[j], zone) then
            add_zone = false
            break
        end
    end
    if add_zone then
        add(result, zone)
    end
  end

  return result
end

-- creates a starry background. should be called once
function generate_background()
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

