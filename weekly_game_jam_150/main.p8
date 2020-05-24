pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- you're the enemy
-- by tarkan al-kazily

#include agents_lib.lua

-- stores all the states
_s = {}
state="main_menu"

-- global time
_t = 0

function _init()
  music(0)
  _s.main_menu = agents_lib_init()
  _s.game = agents_lib_init()
  agents_lib_create(_s.main_menu,
    "main_menu",
    {nil, update_main_menu, draw_main_menu},
    {},
    1)
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
  --create_enemy("slime",{pos={8,8}})

  m_hdl = agents_lib_create(_s.game,
    "map",
    {create_map, update_map, draw_map},
    {},
    1)

  agents_lib_create(_s.game,
    "switches",
    {nil, update_switches, nil},
    {},
    11)

  agents_lib_create(_s.game,
    "stairs",
    {nil, update_stairs, nil},
    {},
    11)
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

function update_main_menu(a)
  if (btnp(5)) state = "game"
end

function draw_main_menu(a)
  spr(80, 32, 50, 8, 1)
  cursor(0, 70)
  print("⬅️ ➡️ ⬆️ ⬇️ to move", 8)
  print("❎ (x) to return to ghost", 8)
  print("")
  print("press ❎ (x) to begin!", 8)
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
  ret.is_monster = false

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
      player.pos = e.pos
      player.monster = e
      player.is_monster = true
    -- respawns the monster
    player._btnp[5] = function(a)
        player.monster.pos = a.pos
        add(enemies_task, player.monster)
        local new_player = create_player(a)
        return new_player
      end
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
    local ret = {a.pos[1] + dx, a.pos[2] + dy}

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
  ret.rate = 7
  ret._update = update_slime
  return ret
end

function update_slime(a)
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
  local player = get_agent(p_hdl)
  camera(128 * (player.pos[1] \ 16), 128 * (player.pos[2] \ 16))
  pal()
  palt(12, true)
  map(a.x, a.y, 0, 0)
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
-- switches, stairs code

-- stores tuples: {switch position(s)}, {door positions}, {on spr, off spr}
_switches = {

  {{{13, 6}}, {{7, 4}, {8, 4}}, {5, 0}}

}

function update_switches(a)
  local player = get_agent(p_hdl)
  for switch in all(_switches) do
    local count, state = 0, 1
    if player.is_monster then
      for switch_pos in all(switch[1]) do
        if l1_distance(player.pos, switch_pos) < 1 then
          count += 1
        end
      end
    end
    for e in all(enemies_task) do
      for switch_pos in all(switch[1]) do
        if l1_distance(e.pos, switch_pos) < 1 then
          count += 1
        end
      end
    end
    if (count == #switch[1]) state = 2
    for pos in all(switch[2]) do
      mset(pos[1], pos[2], switch[3][state])
    end
  end
  return {}
end

-- stores tuples: {start stair pos}, {end stair pos}
_stairs = {
  {{13, 2}, {18, 2}},
}

function update_stairs(a)
  printh("update_switches")
  local player = get_agent(p_hdl)
  if not player.is_monster then
    for stair in all(_stairs) do
      if l1_distance(player.pos, stair[1]) < 1 then
        player.pos = stair[2]
      end
    end
  end
  return {}
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
00000000111111110c4444c0cc4c0000000000006666666600000000111111110000000000000000000000000000000000000000000000000000000000000000
0000000015555151c444444cc45c0000066666606555565600000066100000660000000000000000000000000000000000000000000000000000000000000000
007007001555515155555555554c0000064444606555565600000066100000660000000000000000000000000000000000000000000000000000000000000000
000770001111111154444444544c0000064444606666666600066066100660660000000000000000000000000000000000000000000000000000000000000000
000770001515555154444c44544c0000064444606565555600066066100660660000000000000000000000000000000000000000000000000000000000000000
007007001515555154444c44545c0000064444606565555666066066160660660000000000000000000000000000000000000000000000000000000000000000
000000001515555155555555554c0000066666606565555666066066160660660000000000000000000000000000000000000000000000000000000000000000
00000000111111115444444454c00000000000006666666666066066111111110000000000000000000000000000000000000000000000000000000000000000
00ccc00000ccc00000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c666c000c666c000c666c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c66666c0c66666c0c66666c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c61616c0c66161c0c16166c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c61616c0c66161c0c16166c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c66666c0c66666c0c66666c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc6c6cc0cc6c6cc0cc6c6cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0c0c0c0c0c0c0c0c0c0c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666000000000000600000000000000000000600006000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000066600600060660600060066600600000000666000000000666000000000000000000000000000000000000000000000000000000000000000000
00600060600600000660066000600060600000660006006000600606006000000000000000000000000000000000000000000000000000000000000000000000
00600066060066000600060000600060600000600006006000600660600660000000000000000000000000000000000000000000000000000000000000000000
00600060060000600600060000600060600000600006006000600600600006000000000000000000000000000000000000000000000000000000000000000000
66666060060666000666060000066600066600666006000666000600606660000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001030200010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000006000101000700000400000400000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000200000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010105050101010101010101000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000100000100000000000101010101010105050101010100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000200000200000004000101000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000100000100000000000101000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010100000101010101010101000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000200000200000000000101000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000100000100000000000101000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010100000101010101010101000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0140410000000100000100000000000101000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000200000200000000000101000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0141000000000100000100000000000101000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011800080c003000000c003000000c003180730c00318073000000c0030000000000000000c0030000000000000000c0030000000000000000c0030000000000000000c003000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800080c1500e15010150111500010000100001000c1000c1500e15010150111500e10010100111000c1000c1500e15010150111500e10010100111000c1000c1500e150101501115000000000000000000000
__music__
03 02004344

