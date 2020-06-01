pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- ship game

function _init()
  count = 1
  debug = true
  test_flip = false
  cutoff = 75
end

function _update60()
  if (btnp(0)) count = max(1, count - 1)
  if (btnp(1)) count = count + 1

  --[[
  if (btnp(2)) cutoff += 5
  if (btnp(3)) cutoff = max(5, cutoff - 5)
  ]]

  if (btnp(4)) debug = not debug
  if (btnp(5)) test_flip = not test_flip
end

function _draw()
  cls()
  --line(0, 0, 128, 128, 1)
  --right_triangle(0, 0, 10, 10, 8, false)

  --right_triangle(40, 40, 30, 30, 12, true)

  --right_triangle(80, 80, 96, 100, 11, false)
  --right_triangle(16, 80, 0, 60, 8, false)
  --right_triangle(16, 80, 0, 60, 11, true)
  right_triangle_fill(5, 100, 0, 95, 9, false)

  for i=1,count do
    if (debug) right_triangle(0, 0, 90, 90, 8, test_flip)
    --right_triangle_fill(0, 45, 45, 90, test_flip and 11 or 12, test_flip)
    right_triangle_fill(0, 0, 90, 90, test_flip and 2 or 3, test_flip)
  end

  test_triangle_fill(70, 0, 128, 58, test_flip and 2 or 3, test_flip)
  --right_triangle_fill(0, 60, 60, 80, 12, false)
  --right_triangle_fill(0, 80, 80, 100, 11, false)
  --right_triangle_fill(0, 100, 100, 120, 8, false)
  print(count, 8)
  print(cutoff, 8)
end

-->8
-- ship graphics

function draw_ship()
  -- constants
  local x0, y0 = 0, 0
  local c1, c2, c3, background = 2, 13, 1, 0
  cls(c1)
end

function test_triangle_fill(x0, y0, x1, y1, c, flip)
  local dx, dy = x1 - x0, y1 - y0
  local b, h = abs(dx), abs(dy)
  if (flip) x0, y0, x1, y1, dx, dy = x1, y1, x0, y0, -dx, -dy
  local steps = max(b, h) \ 8
  local dx, dy = dx / steps, dy / steps
  line(x0, y0, x1, y1, c)
  for i=1,steps do
    line(x0, y0 + i * dy)
    line(x1 - i * dx, y1)
  end
end

function right_triangle_fill(x0, y0, x1, y1, c, flip)
  local dx, dy = x1 - x0, y1 - y0
  local b, h = abs(dx), abs(dy)
  if (flip) x0, y0, x1, y1, dx, dy = x1, y1, x0, y0, -dx, -dy
  if ((b < cutoff + 1) and (h < cutoff + 1)) then
    local steps = max(b, h)
    local dx, dy = dx / steps, dy / steps
    line(x0, y0, x1, y1, c)
    for i=1,steps do
      line(x0, y0 + i * dy)
      line(x1 - i * dx, y1)
    end
  else
    local rx, ry = b - cutoff, h - cutoff
    if rx <= 0 then
      assert(ry > 0)
      rx = abs(cutoff * b / h)
    else
      ry = abs(cutoff * h / b)
    end
    local xm, ym = x0 + rx, y1 - ry
    if (flip) xm, ym = x0 - rx, y1 + ry
    rectfill(x0, y1, xm, ym, c)
    right_triangle_fill(x0, y0, xm, ym, c, false)
    right_triangle_fill(xm, ym, x1, y1, c, false)
  end
end

function right_triangle(x0, y0, x1, y1, c, flip)
  if (flip) x0, y0, x1, y1 = x1, y1, x0, y0
  line(x0, y0, x1, y1, c)
  line(x0, y1)
  line(x0, y0)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
