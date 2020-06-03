pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- tic-tac-toe
-- by tarkan al-kazily

function _init()
  menu = {update=menu_update, draw=menu_draw}
  game = {update=game_update, draw=game_draw}

  state = menu

  -- constants
  div=128/3
  ai_delay = 0.5
  reset_delay = 2.0

  -- menu modes
  menu_item = 1

  -- ai settings
  ai = 1
  ai_1_mode = 1
  ai_2_mode = 1
  ai_modes = {
    {ai_random, "random"},
    --{ai_minimax, "minimax"},
    --{ai_negamax, "negamax"},
    {ai_alpha_beta, "alpha beta"},
  }
  player_first = true
end

function _update60()
  state.update()
end

function _draw()
  state.draw()
end

function menu_update()
  if (menu_item == 1) then
    if (btnp(0)) ai = mid(0, ai + 1, 2)
    if (btnp(1)) ai = mid(0, ai - 1, 2)
  elseif (menu_item == 2) then
    if (btnp(0)) ai_1_mode = mid(1, ai_1_mode - 1, #ai_modes)
    if (btnp(1)) ai_1_mode = mid(1, ai_1_mode + 1, #ai_modes)
  elseif (menu_item == 3) and (ai == 2) then
    if (btnp(0)) ai_2_mode = mid(1, ai_2_mode - 1, #ai_modes)
    if (btnp(1)) ai_2_mode = mid(1, ai_2_mode + 1, #ai_modes)
  elseif (menu_item == 3) and (ai == 1) then
    if (btnp(0) or btnp(1)) player_first = not player_first
  end

  if (btnp(2)) menu_item = mid(1, menu_item - 1, ai >= 1 and 3 or 1)
  if (btnp(3)) menu_item = mid(1, menu_item + 1, ai >= 1 and 3 or 1)

  -- transition to game
  if btnp(4) or btnp(5) then
    game_init()
    state = game
  end
end

function menu_title_draw()
  local x, y = 24, 8
  pal(11, 8)
  sspr(0, 0, 16, 16, x, y)
  sspr(16, 0, 16, 16, x + 16, y)
  sspr(32, 0, 16, 16, x + 32, y)
  y += 16
  x += 16
  pal(11, 12)
  sspr(0, 0, 16, 16, x, y)
  sspr(8*8, 0, 16, 16, x + 16, y)
  sspr(32, 0, 16, 16, x + 32, y)
  y += 16
  x += 16
  pal(11, 10)
  sspr(0, 0, 16, 16, x, y)
  sspr(6*8, 0, 16, 16, x + 16, y)
  sspr(10*8, 0, 16, 16, x + 32, y)
  
  y += 20
  x = 20

  pal()
  s = "would you like to play a game?"
  print(s, (128 - #s * 4) / 2, y, 2)
  y += 8
  c = 12
  if (menu_item == 1) c = 8
  print("number of players: "..(2-ai), x, y, c)

  y += 8
  c = 12
  if (menu_item == 2) c = 8
  if ai >= 1 then
    print("ai 1 type: "..ai_modes[ai_1_mode][2], x, y, c)
  end

  y += 8
  c = 12
  if (menu_item == 3) c = 8
  if ai == 1 and player_first then
    print("player goes first", x, y, c)
  elseif ai == 1 and not player_first then
    print("player goes second", x, y, c)
  end

  c = 12
  if (menu_item == 3) c = 8
  if ai >= 2 then
    print("ai 2 type: "..ai_modes[ai_2_mode][2], x, y, c)
  end

  y += 8
  print("press 🅾️/❎ to begin", x, y, 10)
end

function menu_draw()
  cls(0)
  menu_title_draw()

end

-->8
function game_init()
  cur_ai_id = 1

  -- flat 3x3 board
  winner = 0
  winning_moves = nil

  -- current player
  player_id = 1
  p_x, p_y = 2,2
  last_t = 0

	board = new_board()

  if ai == 1 and not player_first then
    player_id = 2
    board = ai_modes[ai_1_mode][1](board, 1)
  end
end

function game_update()
  local just_ended = (winner == 0)
  if ai < 2 then
    board = update_player(board)
    winner, winning_moves = evaluate_board(board)
  end
  if winner == 0 and ai == 2 then
    if t() - last_t > ai_delay then
      last_t = t()

      ai_mode = (cur_ai_id == 1) and ai_1_mode or ai_2_mode
      board = ai_modes[ai_mode][1](board, cur_ai_id)
      winner, winning_moves = evaluate_board(board)

      cur_ai_id = cur_ai_id % 2 + 1
    end
  end

  if winner != 0 then
    if just_ended then
      if (winner > 0) sfx(1)
      if (winner == -1) sfx(2)
      game_end = t()
    end
    if t() - game_end > reset_delay then
      ai_delay = max(0.001, ai_delay * 0.6)
      reset_delay = max(0.01, reset_delay * 0.6)
      game_init()
    end
  end
end

function game_draw()
  cls(0)
  if winner == 0 then
    draw_player()
  else
    draw_winner()
  end
  draw_board(board)
end
-->8
-- game board

function new_board()
 local board = {0,0,0,0,0,0,0,0,0}
 return board
end

-- deep copy of a table object
function copy(b)
  if type(b) != "table" then
    return b
  end
  local result = {}
  for k, v in pairs(b) do
    local _k, _v = copy(k), copy(v)
    result[_k] = _v
  end
  return result
end

-- getter for board b
-- square is a two entry table {x, y}
function board_get(b, square)
 local x, y = unpack(square)
 return b[3*(x-1)+y]
end

-- setter for board b
-- square is a two entry table {x, y}
-- p is the player id (or 0 if empty)
function board_set(b, square, p)
 local x, y = unpack(square)
 b[3*(x-1)+y] = p
end

function board_is_empty(b)
  for v in all(b) do
    if (v != 0) return false
  end
  return true
end

-- draws the board b on the screen
function draw_board(b)
 rect(div, -10, 2*div, 138, 1)
 rect(-10, div, 138, 2*div, 1)
 for x=1,3 do
  for y=1,3 do
    local v = board_get(b, {x, y})
    if v == 1 then
      -- draw x
      x1, y1 = div * x-5, div * y -5
      line(x1-div+10, y1-div+10, x1, y1,8)
      line(x1, y1-div+10, x1-div+10, y1,8)
    elseif v == 2 then
      -- draw o
      circ(div * x - div/2, div * y - div/2, div/2 - 5, 12)
    end
  end
 end
end

-->8
-- player code

function update_player(b)
  local new_b = b

	if (btnp(0)) p_x -= 1
	if (btnp(1)) p_x += 1

	if (btnp(2)) p_y -= 1
	if (btnp(3)) p_y += 1

	p_x = mid(1, p_x, 3)
	p_y = mid(1, p_y, 3)
	
  if (btnp(4) or btnp(5)) then
    local move = {p_x, p_y}
    if is_legal(b, move) then
      new_b = make_move(b, move, player_id)
      winner, winning_moves = evaluate_board(new_b)
      if winner == 0 and ai == 1 then
        new_b = ai_modes[ai_1_mode][1](new_b, player_id % 2 + 1)
      else
        player_id = player_id % 2 + 1
      end
    else
      sfx(0)		
    end	
  end
  return new_b
end

function draw_player()
  local c = player_id == 1 and 8 or 12
  if ((t() \ 0.75) % 2 == 1) c = 0
  rectfill((p_x-1)*div,(p_y-1)*div, p_x*div, p_y*div, c)
  rect((p_x-1)*div+2,(p_y-1)*div+2, p_x*div-2, p_y*div-2, 13)
end
-->8

function draw_winner()
  local c = (winner > 0) and 10 or 5
  if (t() \ 0.5) % 3 == 2 then
    c = 0
  end
  if winner > 0 then
    for pos in all(winning_moves) do
      local x,y = pos[1], pos[2]
      rectfill((x-1)*div,(y-1)*div,x*div,y*div,c)
    end
  elseif winner == -1 then
    for x=1,3 do
      for y=1,3 do
        rectfill((x-1)*div,(y-1)*div,x*div,y*div,c)
      end
    end
  end
end

-->8

--[[
functions for ai and general turn based functionality
]]

-- returns all moves associated with a board
function get_moves(b)
  if board_is_empty(b) then
    return {{1,1}, {1, 2}, {2, 2}}
  end
  
  local result = {}
  for x=1,3 do
    for y=1,3 do
      add(result, {x, y})
    end
  end

  return result
end

-- returns true iff move is legal on board b
function is_legal(b, move)
  return (board_get(b, move) == 0)
end

-- applies the move by player, returning a new board
function make_move(b, move, player)
  if (move == nil) return b
  assert(is_legal(b, move))
  local new_b = copy(b)
  board_set(new_b, move, player)
  return new_b
end

-- evaluates board for winner or draw
-- returns 0 for no winner, player_id if winner, -1 if draw
function evaluate_board(b)
  local moves, w = nil, nil
  for x=1,3 do
    moves = {{x, 1}, {x, 2}, {x, 3}}
    w = _check_triple(b, moves)
    if (w != 0) return w, moves
  end
  for y=1,3 do
    moves = {{1, y}, {2, y}, {3, y}}
    w = _check_triple(b, moves)
    if (w != 0) return w, moves
  end
  moves = {{1, 1}, {2, 2}, {3, 3}}
  w = _check_triple(b, moves)
  if (w != 0) return w, moves
  moves = {{3, 1}, {2, 2}, {1, 3}}
  w = _check_triple(b, moves)
  if (w != 0) return w, moves

  -- no winner, check for draw
  for v in all(b) do
    if (v == 0) return 0, nil
  end
  
  -- draw
  return -1, nil
end

-- helper for evaluate board for tic-tac-toe
function _check_triple(b, moves)
  local v = {}
  for m in all(moves) do
    add(v, board_get(b, m))
  end
  if v[1] == 0 then
    return 0
  end
  return ((v[1] == v[2]) and (v[1] == v[3])) and v[1] or 0
end

-->8
-- ai

function get_legal_moves(b, shuffle)
  local moves = get_moves(b)
  for m in all(moves) do
    if (not is_legal(b, m)) del(moves, m)
  end
  if shuffle then
    local _moves = moves
    moves = {}
    while #_moves > 0 do
      add(moves, rnd(_moves))
      del(_moves, moves[#moves])
    end
  end
  return moves
end

-- random
function ai_random(b, ai_id)
  local moves = get_legal_moves(b, false)
  return make_move(b, rnd(moves), ai_id)
end

function ai_minimax(b, ai_id)
  return _ai_minimax(b, ai_id, true)
end

function _ai_minimax(b, maximizing_id, maximize)
  local opponent, w, _m = (maximizing_id % 2 + 1), evaluate_board(b)
  -- check for winners
  if w == maximizing_id then
    return b, 1
  end
  if w == opponent then
    return b, -1
  end
  if w == -1 then
    return b, 0
  end

  local moves, best_board = get_legal_moves(b, false), b
  if maximize then
    local best_value = -10
    for m in all(moves) do
      local m_b = make_move(b, m, maximizing_id)
      local _, m_v = _ai_minimax(m_b, maximizing_id, false)
      if best_value < m_v then
        best_value = m_v
        best_board = m_b
      end
    end
    return best_board, best_value
  else
    local best_value = 10
    for m in all(moves) do
      local m_b = make_move(b, m, opponent)
      local _, m_v = _ai_minimax(m_b, maximizing_id, true)
      if best_value > m_v then
        best_value = m_v
        best_board = m_b
      end
    end
    return best_board, best_value
  end
end

-- negamax search
function ai_negamax(b, ai_id)
  local opponent, w, _m = (current_id % 2 + 1), evaluate_board(b)
  -- check for winners
  if w == current_id then
    return b, 1
  end
  if w == opponent then
    return b, -1
  end
  if w == -1 then
    return b, 0
  end

  local moves, best_value, best_board = get_legal_moves(b, false), -10, b
  for m in all(moves) do
    local m_b = make_move(b, m, current_id)
    local _, m_v = ai_negamax(m_b, opponent)
    if -m_v > best_value then
      best_value = -m_v
      best_board = m_b
    end
  end
  return best_board, best_value
end

-- alpha beta pruning search
function ai_alpha_beta(b, ai_id)
  return _ai_alpha_beta(b, ai_id, -10, 10)
end

function _ai_alpha_beta(b, ai_id, alpha, beta)
  local opponent, w, _m = (ai_id % 2 + 1), evaluate_board(b)
  -- ai scoring heuristics
  if w == ai_id then
    return b, 1
  elseif w == opponent then
    return b, -1
  elseif w == -1 then
    return b, 0
  end

  local moves, best_value, best_board = get_legal_moves(b, true), -100, b
  for m in all(moves) do
    local m_b = make_move(b, m, ai_id)
    local _, m_v = _ai_alpha_beta(m_b, opponent, -beta, -alpha)
    if -m_v > best_value then
      best_value = -m_v
      best_board = m_b
    end
    alpha = max(alpha, best_value)
    if alpha >= beta then
      return best_board, best_value
    end
  end
  return best_board, best_value
end

function to_hash(args)
  local hash = ""
  for v in all(args) do
    local _type = sub(type(v), 1, 2)
    hash = hash.._type
    if _type == "ta" then
      hash = hash..to_hash(v)
    else
      hash = hash..tostr(v)
    end
  end
  return hash
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb0000000000000bbbbbbbbbbbbb0000000bbbbbb0000000000bbbbbb000000000000bb0000000000bbbbbbbbbb00000000000000000000000000000000000
0bbbbbbbbbbbbb0000bbbbbbbbbbbbb0000bbbbbbbbbb000000bbbbbbbbbb000000000bbbb00000000bbbbbbbbbbbb0000000000000000000000000000000000
00bbbbbbbbbbbbb00000000bb000000000bbbb0000bbbb0000bbbb0000bbbb00000000bbbb00000000bbb0000000000000000000000000000000000000000000
0000000bb000bbb00000000bb000000000bbb000000bbb0000bbb000000bbb0000000bb00bb0000000bb00000000000000000000000000000000000000000000
0000000bb00000000000000bb000000000bb00000000000000bb00000000bb0000000bb00bb0000000bb00000000000000000000000000000000000000000000
0000000bb00000000000000bb000000000bb00000000000000bb00000000bb000000bb0000bb000000bb00000000000000000000000000000000000000000000
0000000bb00000000000000bb000000000bb00000000000000bb00000000bb000000bb0000bb000000bbbbbbbb00000000000000000000000000000000000000
0000000bb00000000000000bb000000000bb00000000000000bb00000000bb000000bb0000bb000000bbbbbbbbb0000000000000000000000000000000000000
0000000bb00000000000000bb000000000bb00000000000000bb00000000bb00000bbbbbbbbbb00000bb00000000000000000000000000000000000000000000
0000000bb00000000000000bb000000000bb00000000000000bb00000000bb00000bbbbbbbbbb00000bb00000000000000000000000000000000000000000000
0000000bb00000000000000bb000000000bbb000000bbb0000bbb000000bbb0000bbbb0000bbbb0000bb00000000000000000000000000000000000000000000
0000000bb00000000000000bb000000000bbbb0000bbbb0000bbbb0000bbbb0000bbb000000bbb0000bbb0000000000000000000000000000000000000000000
0000000bb00000000bbbbbbbbbbbbb00000bbbbbbbbbb000000bbbbbbbbbb0000bbb00000000bbb000bbbbbbbbbbbb0000000000000000000000000000000000
0000000bb000000000bbbbbbbbbbbbb000000bbbbbb0000000000bbbbbb000000bbb00000000bbb0000bbbbbbbbbb00000000000000000000000000000000000
__sfx__
010a00001a0700e075120051200512005120051100511005090050400500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
010c00002104423040240402802000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001804218042130421304200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
