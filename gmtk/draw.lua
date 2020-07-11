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
  circfill(z.pos.x, z.pos.y, z.radius, z.color)
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
    print(e.current_target, e.state.q.x + 10, e.state.q.y, 7)
  elseif e.type == "zone" then
    circfill(e.state.q.x, e.state.q.y, e.radius, e.color)
    print(flr(e.point), e.state.q.x, e.state.q.y, 7)
  end
end

