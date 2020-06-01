pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- ship game

function _init()
  count = 1
  new_frame = true
end

function _update60()
  if (btnp(0)) count = max(1, count - 1)
  if (btnp(1)) count = count + 1

  if (btnp(4) or btnp(5)) new_frame = true
end

function _draw()
  if new_frame then
    cls()
    for i=1,count do
      triangle_fill(rnd(128), rnd(128), rnd(128), rnd(128), rnd(128), rnd(128), i % 15 + 1)
    end
    new_frame = false
  end
end

-->8
-- graphics

function triangle(x0, y0, x1, y1, x2, y2, c)
  line(x0, y0, x1, y1, c)
  line(x2, y2)
  line(x0, y0)
end


function _triangle_fill(x0, y0, x1, y1, x2, y2, c)
  local dya, dyb, dyc = y0 - y1, y0 - y2, y1 - y2
  local xs, ys, xe, ye = x0, y0, x0, y1
  local dxa, dxb, dxc = 0, 0, 0
  if (abs(dya) > 0) dxa = (x0 - x1) / dya
  if (abs(dyb) > 0) dxb = (x0 - x2) / dyb
  if (abs(dyc) > 0) dxc = (x1 - x2) / dyc
  while ys <= ye do
    line(xs, ys, xe, ys, c)
    ys += 1
    xs += dxa
    xe += dxb
  end
  local xs, ys, xe, ye = x2, y2, x2, y1
  while ys >= ye do
    line(xs, ys, xe, ys, c)
    ys -= 1
    xs -= dxb
    xe -= dxc
  end
end

function triangle_fill(x0, y0, x1, y1, x2, y2, c)
  local _x0, _y0, _x1, _y1, _x2, _y2 = x0, y0, x1, y1, x2, y2
  if _y0 > _y1 or _y0 > _y2 then
    if (_y0 > _y1) _x0, _y0, _x1, _y1 = _x1, _y1, _x0, _y0
    if (_y0 > _y2) _x0, _y0, _x2, _y2 = _x2, _y2, _x0, _y0
  end
  if (_y1 > _y2) _x1, _y1, _x2, _y2 = _x2, _y2, _x1, _y1
  _triangle_fill(_x0, _y0, _x1, ceil(_y1), _x2, _y2, c)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
