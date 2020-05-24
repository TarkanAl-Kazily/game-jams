pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- you're the enemy
-- by tarkan al-kazily

#include agents_lib.lua

-- stores all the states
_s = {}
state="game"

-- global time
_t = 0

function _init()
  _s.game = agents_lib_init()
  p_hdl = agents_lib_create(_s.game,
    "player",
    {create_player, update_player, draw_player},
    {pos={1, 13}},
    10)

  enemies_hdl = agents_lib_create(_s.game,
    "enemies",
    {nil, update_enemies, draw_enemies},
    enemies_task,
    9)

  create_enemy("slime",{pos={1,5}})
  create_enemy("slime",{pos={8,8}})

  m_hdl = agents_lib_create(_s.game,
    "map",
    {create_map, update_map, draw_map},
    {},
    1)
end

function _update60()
  _t += 1
  agents_lib_update(_s[state])
end

function _draw()
  cls()
  agents_lib_draw(_s[state])
end

function get_agent(hdl)
  return _s[state].agents[hdl]
end

function remove_agent(hdl)
  agents_lib_remove(_s[state], hdl)
end

-->8
--> entity code

--[[
 structure representing a mobile entity with an animation
 suggested entries in args:
 - x, y: initial position for entity
 - ani: sequence of frames for animation
]]
function create_mob(args)
  local ret = {
    pos={0, 0},
    ani={1}, frame=1, rate=0,
    _draw=draw_mob
  }
  ret = merge_tables(ret, args)
  return ret
end

--[[
 structure representing player
]]
function create_player(args)
  local ret = create_mob(args)

  -- add additional state/functionality here
  ret.ani = {16, 17, 16, 18}
  ret.rate = 15
  ret._btnp = {}
  ret._btnp[0] = move_entity(0)
  ret._btnp[1] = move_entity(1)
  ret._btnp[2] = move_entity(2)
  ret._btnp[3] = move_entity(3)
  ret._btnp[4] = function() return {} end
  ret._btnp[5] = function() return {} end
  ret._interact = player_interact

  return ret
end

function update_player(a)
  if (not PLAYER_ACTIVE) return {}

  -- handle button input
  local next_state = {}
  local acted = false
  for i=0,5 do
    if (btnp(i)) then
      next_state = merge_tables(next_state, a._btnp[i](a))
    end
  end

  if next_state.pos != nil then
    for e in all(enemies_task) do
      local d = l1_distance(next_state.pos, e.pos)
      if d < 1 then
        a._interact(a, e)
        acted = true
      end
    end

    -- handle turn
    if (next_state.pos[1] != a.pos[1] or next_state.pos[2] != a.pos[2]) then
      acted = true
    end
  end

  if (acted) PLAYER_ACTIVE = false
  return next_state
end

--[[
 handles the player interaction when trying to move into a new position

 returns:
  true if some interaction happened. in this case, player has been modified
]]
function player_interact(player, pos)
  -- check for door at pos
  if get_flag_at(pos, DOOR) then
    -- saves the door state
    player.ani = {mget(pos[1], pos[2])}
    mset(pos[1], pos[2], 0)
    player.f = 1
    player.pos = pos
    for i=0,3 do
      player._btnp[i] = function(a)
          player.ani = {((player.ani[1] + 1) % 2) + 2}
        end
    end
    -- respawns the door
    player._btnp[5] = function(a)
        mset(a.pos[1], a.pos[2], a.ani[1])
        local new_player = create_player(a)
        return new_player
      end
    player._interact = dont_interact
    return true
  end

  -- become the enemy!
  for e in all(enemies_task) do
    if l1_distance(e.pos, pos) < 1 then
      ret = true
      player.ani = e.ani
      player.rate = e.rate
      player.f = 1
      player._btnp[5] = create_player
      player._interact = dont_interact
      del(enemies_task, e)
      return true
    end
  end
  return false
end

--[[
 handles when the player is not a ghost
]]
function dont_interact(player, pos)
  return false
end

function draw_player(a)
  --rectfill(a.pos[1] * 8, a.pos[2] * 8, a.pos[1] * 8 + 8, a.pos[2] * 8 + 8, 7)
  palt()
  pal({[2]=1, [12]=9})
  draw_mob(a)
end

function draw_mob(a, pal_args)
  if a.rate > 0 then
    a.frame = ((_t \ a.rate) % #a.ani) + 1
  end
  spr(a.ani[a.frame], a.pos[1] * 8, a.pos[2] * 8)
end

function move_entity(dir)
  local dx = 0
  local dy = 0
  if (dir == 0) dx = -1
  if (dir == 1) dx = 1
  if (dir == 2) dy = -1
  if (dir == 3) dy = 1

  return function(a) 
    local ret = {mid(0, a.pos[1] + dx, 15), mid(0, a.pos[2] + dy, 15)}

    if a._interact != nil and a._interact(a, ret) then
      return a
    elseif get_flag_at(ret, SOLID) then
      -- handle collision
      return a
    end

    return {pos=ret}
  end
end

-->8
-- enemy manager task code

enemies_hdl = nil
enemies_task = {}

function create_enemy(enemy_type, args)
  local e = nil
  if enemy_type == "slime" then
    e = create_slime(args)
  else
    assert("invalid type: "..enemy_type)
  end
  add(enemies_task, e)
end

function update_enemies(a)
  if not (PLAYER_ACTIVE) then
    for e in all(a) do
      e._update(e)
    end
    PLAYER_ACTIVE = true
  end
  return {}
end

function draw_enemies(a)
	palt(12, true)
  for e in all(a) do
    e._draw(e)
  end
  cursor(1, 1)
  print(#enemies_task, 8)
end

-->8
-- individual enemy code

-- slimes: green, small, simple!
function create_slime(args)
  local ret = create_mob(args)
  ret.ani = {32, 33, 34, 34}
  ret.rate = 5
  ret._update = update_slime
  return ret
end

function update_slime(a)
  local _player_pos = get_agent(p_hdl).pos

  if l1_distance(a.pos, _player_pos) < 5 then
    local d = distances(_player_pos)
    local next_pos = a.pos
    local best_dist = d[next_pos[1] * 16 + next_pos[2]]
    for v in all(neighbors4(a.pos)) do
      dv = d[v[1] * 16 + v[2]]
      if dv < best_dist then
        next_pos = v
        best_dist = dv
      end
    end
    a.pos = next_pos
  end
  printh(a.pos[1]..','..a.pos[2])
end

-->8
-- map code

-- sprite flag constants
SOLID = 0
DOOR = 1

function create_map(args)
  local ret = {x=0, y=0, w=16, h=16}
  return merge_tables(ret, args)
end

function update_map(a)
end

function draw_map(a)
  pal()
  palt(12, true)
  map(a.x, a.y, 0, 0, a.w, a.h)
end

function get_flag_at(pos, ...)
  return fget(mget(pos[1], pos[2]), ...)
end

--[[
 computes the distance from every cell to pos
]]
function distances(pos)
  local res = {}
  local q = {{pos[1], pos[2], 0}}
  local h = 1
  while h <= #q do
    local v = q[h]
    h += 1
    local idx = v[1] * 16 + v[2]
    if (res[idx] == nil) or (v[3] < res[idx]) then
      res[idx] = v[3]
      for u in all(neighbors4(v)) do
        add(q, {u[1], u[2], v[3] + 1})
      end
    end
  end
  return res
end

function neighbors4(x, y)
  local _x, _y = x, y
  if _y == nil then
    _x, _y = x[1], x[2]
  end
  local res = {{_x, _y+1}, {_x, _y-1}, {_x+1, _y}, {_x-1, _y}}
  for v in all(res) do
    if (get_flag_at(v, SOLID)) del(res, v)
    if (v[1] < 0 or v[1] > 15 or v[2] < 0 or v[2] > 15) del(res, v)
  end
  return res
end

function draw_distances(pos)
  local d = distances(pos)
  for _x=0,15 do
    for _y=0,15 do
      local _d = d[_x * 16 + _y]
      if _d != nil then
        cursor(_x * 8, _y * 8)
        print(_d)
      end
    end
  end
end

-->8
-- util functions

function merge_tables(base, other)
  for k, v in pairs(other) do
    base[k] = v
  end
  return base
end

--[[
 implements manhattan distance
]]
function l1_distance(pos1, pos2)
  return abs(pos2[1] - pos1[1]) + abs(pos2[2] - pos1[2])
end

__gfx__
00000000111111110c4444c0cc4c0000000000000000000075000077777777777555557775555577777755777705707777077077000000000000000000000000
0000000015555151c444444cc45c0000000000000000000075057077777755557777757777777577777557777705705775057075000000000000000000000000
007007001555515155555555554c0000000000000000000075057077000000000000007700000077550000005705700000057075000000000000000000000000
000770001111111154444444544c0000000000000000000075077077077775507777705777777057570775555507755777777075000000000000000000000000
000770001515555154444c44544c0000000000000000000077077057055777707557705575577055570777777507777755577075000000000000000000000000
007007001515555154444c44545c0000000000000000000077075057000000000007507500075075570750007700000000000055000000000000000000000000
000000001515555155555555554c0000000000000000000077075057555577777507507775075077570750577757777777755777000000000000000000000000
00000000111111115444444454c00000000000000000000077000057777777777707507777075077770770777755555777557777000000000000000000000000
00ccc00000ccc00000ccc00000000000000000007777000000007777000000000000000000000000000000000000000000000000000000000000000000000000
0c666c000c666c000c666c0000000000000000007666700000076667000000000000000000000000000000000000000000000000000000000000000000000000
c66666c0c66666c0c66666c000000000000000000766677007766670000000000000000000000000000000000000000000000000000000000000000000000000
c61616c0c66161c0c16166c000000000000000000765656776565670000000000000000000000000000000000000000000000000000000000000000000000000
c61616c0c66161c0c16166c000000000000000000065656776565600000000000000000000000000000000000000000000000000000000000000000000000000
c66666c0c66666c0c66666c000000000000000000666666666666660000000000000000000000000000000000000000000000000000000000000000000000000
cc6c6cc0cc6c6cc0cc6c6cc000000000000000006666666666666666000000000000000000000000000000000000000000000000000000000000000000000000
c0c0c0c0c0c0c0c0c0c0c0c000000000000000006060606006060606000000000000000000000000000000000000000000000000000000000000000000000000
000ccc000000000000000000000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c333c0000ccc00000ccc0000c333c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c3333c000c333c000c333c00c3333c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c323233c0c3333c00c3333c0c332323c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c323233cc323233cc332323cc332323c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c333333cc323233cc332323cc333333c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c333333cc333333cc333333cc333333c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cccccc00cccccc00cccccc00cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066600000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666660660556600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00606060666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00606060060056600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060600000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066600005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060600005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001030200000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0140410000010000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000020000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0141000000010000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
