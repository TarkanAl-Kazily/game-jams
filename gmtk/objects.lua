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
    result.state.q.x = rnd_between(32, 96)
    result.state.q.y = rnd_between(32, 96)
    result.limits = miner_settings
    result.type = "miner"
    result.current_target = flr(rnd(#miner_targets) + 1)
    result.zero_target_zone = nil
    return result
end

-- creates a player ship
function new_player()
    local result = new_miner()
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

function new_moving_zone()
  local moving_zone = new_zone()
  local start_side, start_pos = flr(rnd(4)), rnd_between(world_bounds.min.x, world_bounds.max.x)
  local x_vel, y_vel = rnd_between(1.0, 15.0), rnd_between(1.0, 15.0)
  if start_side == 0 then
      moving_zone.state.q.x = world_bounds.min.x
      moving_zone.state.q.y = start_pos
      moving_zone.state.q_dot.x = x_vel
      moving_zone.state.q_dot.y = y_vel * ((rnd(1) < 0.5) and 1.0 or -1.0)
  elseif start_side == 1 then
      moving_zone.state.q.x = world_bounds.max.x
      moving_zone.state.q.y = start_pos
      moving_zone.state.q_dot.x = -x_vel
      moving_zone.state.q_dot.y = y_vel * ((rnd(1) < 0.5) and 1.0 or -1.0)

  elseif start_side == 2 then
      moving_zone.state.q.x = start_pos
      moving_zone.state.q.y = world_bounds.min.y
      moving_zone.state.q_dot.x = x_vel * ((rnd(1) < 0.5) and 1.0 or -1.0)
      moving_zone.state.q_dot.y = y_vel

  elseif start_side == 3 then
      moving_zone.state.q.x = start_pos
      moving_zone.state.q.y = world_bounds.max.y
      moving_zone.state.q_dot.x = x_vel * ((rnd(1) < 0.5) and 1.0 or -1.0)
      moving_zone.state.q_dot.y = -y_vel
  end

  moving_zone.point = 25
  moving_zone.radius = 2.5
  moving_zone.point_growth = 10
  moving_zone.point_cap = 25
  moving_zone.color = 12
  return moving_zone
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
      zone.point_growth = 2.0
      zone.point_cap = 400
    elseif size < 5 then
      -- medium planet
      zone.radius = 15
      zone.color = 13
      zone.point_growth = 3.0
      zone.point_cap = 100
    else
      zone.radius = 5
      zone.color = 5
      zone.point_growth = 4.0
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

