pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- tic-tac-toe
-- by tarkan al-kazily

-- constants
div=128/3

-- flat 3x3 board
board = {}
winner = 0
winning_moves = nil

function _init()
	board = new_board()
end

function _update60()
	if (winner == 0)	board = update_player(board)
	winner, winning_moves = evaluate_board(board)
end

function _draw()
  cls(0)
  t += 1
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

-- current player
player_id = 1
p_x, p_y = 2,2
t = 0

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
			player_id = player_id % 2 + 1
		else
			sfx(0)		
		end	
	end
  return new_b
end

function draw_player()
  local c = player_id == 1 and 8 or 12
  if ((t \ 35) % 2 == 1) c = 0
  rectfill((p_x-1)*div,(p_y-1)*div, p_x*div, p_y*div, c)
  rect((p_x-1)*div+2,(p_y-1)*div+2, p_x*div-2, p_y*div-2, 13)
end
-->8

function draw_winner()
  local c = (winner > 0) and 10 or 5
  if (t \ 35) % 3 == 2 then
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

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010a00001a0700e075120051200512005120051100511005090050400500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
