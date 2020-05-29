pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- tic-tac-toe

function _init()
	setup_board()
end

function _update60()
	if (winner == 0)	update_player()
	check_game_end()
end

function _draw()
	cls(0)
	t += 1
	if winner == 0 then
 	draw_player()
 else
 	draw_winner()
 end
 draw_board()
end
-->8
-- game board

-- constants
div=128/3

-- flat 3x3 board
board = {}

function setup_board()
 board = {0,0,0,0,0,0,0,0,0}
end

function board_get(x, y)
 return board[3*(x-1)+y]
end

function board_set(x, y, v)
 board[3*(x-1)+y] = v
end

function draw_board()
 rect(div, -10, 2*div, 138, 1)
 rect(-10, div, 138, 2*div, 1)
 for x=1,3 do
  for y=1,3 do
			draw_move(x, y)
  end
 end
end

function draw_move(x, y)
	local v = board_get(x, y)
	if v == 1 then
		x1, y1 = div * x-5, div * y -5
		line(x1-div+10, y1-div+10, x1, y1,8)
		line(x1, y1-div+10, x1-div+10, y1,8)
	elseif v == 2 then
		circ(div * x - div/2, div * y - div/2, div/2 - 5, 12)
	end
end
-->8
-- player code

-- current player
player_id = 1
p_x,p_y = 2,2
t = 0

function update_player()
	if (btnp(0)) p_x -= 1
	if (btnp(1)) p_x += 1

	if (btnp(2)) p_y -= 1
	if (btnp(3)) p_y += 1

	p_x = mid(1, p_x, 3)
	p_y = mid(1, p_y, 3)
	
	if (btnp(4) or btnp(5)) then
		if board_get(p_x, p_y) == 0 then
			board_set(p_x, p_y, player_id)
			player_id = player_id % 2 + 1
		else
			sfx(0)		
		end	
	end
end

function draw_player()
 local c = player_id == 1 and 8 or 12
 --if (board_get(p_x, p_y) != 0) c = 14
 if ((t \ 35) % 2 == 1) c = 0
 rectfill((p_x-1)*div,(p_y-1)*div, p_x*div, p_y*div, c)
	rect((p_x-1)*div+2,(p_y-1)*div+2, p_x*div-2, p_y*div-2, 13)
end

-->8

winner = 0
winning_moves = nil


function check_game_end()
 for x=1,3 do
  v1 = board_get(x, 1)
  if v1 != 0 then
  	v2, v3 = board_get(x, 2), board_get(x, 3)
  	if v1 == v2 and v1 == v3 then
  		winner = v1
  		winning_moves = {{x,1},{x,2},{x,3}}
  		return
  	end
  end
 end
	for y=1,3 do
	 v1 = board_get(1,y)
  if v1 != 0 then
  	v2, v3 = board_get(2, y), board_get(3, y)
  	if v1 == v2 and v1 == v3 then
  		winner = v1
  		winning_moves = {{1,y},{2,y},{3,y}}
  		return
  	end
  end
	end
	v1=board_get(2,2)
	if v1 != 0 then
		v2, v3 = board_get(1,1), board_get(3,3)
		if v1 == v2 and v1 == v3 then
			winner = v1
			winning_moves = {{1,1},{2,2},{3,3}}
			return
		end
		v2, v3 = board_get(1,3), board_get(3,1)
		if v1 == v2 and v1 == v3 then
			winner = v1
			winning_moves = {{1,3},{2,2},{3,1}}
			return
		end
	end
end

function draw_winner()
	local c = 10
	if (t \ 35) % 3 == 2 then
		c = 0
	end
 for pos in all(winning_moves) do
  local x,y = pos[1], pos[2]
  rectfill((x-1)*div,(y-1)*div,x*div,y*div,c)
 end
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
