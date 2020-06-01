pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- ship game

function _init()
  cam_x, cam_y = 10, 10
  -- ply format
  mesh1 = {
    {
      {0, 0, 50},
      {20, 0, 50},
      {0, 20, 50},
      {20, 20, 50},
      {0, 0, 30},
      {20, 0, 30},
      {0, 20, 30},
      {20, 20, 30},
    },
    {
      {1, 2, 3},
      {4, 2, 3},
      {1, 2, 5},
      {6, 2, 5},
      {1, 3, 5},
      {7, 3, 5},
      {4, 2, 8},
      {6, 2, 8},
      {4, 3, 8},
      {7, 3, 8},
      {5, 6, 7},
      {8, 6, 7},
    }
  }

  mesh2 = {
    {
      {0, 0, 10},
      {0, 10, 10},
      {10, 0, 10},
      {10, 10, 10},
      {0, 0, 20},
      {0, 10, 20},
      {10, 0, 20},
      {10, 10, 20},
      {0, 0, 30},
      {0, 10, 30},
      {10, 0, 30},
      {10, 10, 30},
      {0, 0, 40},
      {0, 10, 40},
      {10, 0, 40},
      {10, 10, 40},
    },
    {
      {9, 10, 11}, {12, 10, 11},
      {13, 14, 15}, {16, 14, 15},
      {1, 2, 3}, {4, 2, 3},
      {5, 6, 7}, {8, 6, 7},
    }
  }
  mesh_id = 1
  meshes = {mesh1, mesh2}

  cam = {
    {cam_x, cam_y, 0}, {0, 0, 0}
  }

end

function _update60()
  if (btn(0)) cam_x -= 1
  if (btn(1)) cam_x += 1
  if (btn(2)) cam_y -= 1
  if (btn(3)) cam_y += 1
  if (btnp(4)) mesh_id = mesh_id % #meshes + 1
  cam = {
    {-cam_x, -cam_y, 0}, {0, 0, 0}
  }
end

function _draw()
  cls(0)
  draw_mesh(cam, meshes[mesh_id])
  print(cam_x)
  print(cam_y)
end

-->8
-- ship graphics

function draw_mesh(cam, mesh)
  local _vertices, _faces = mesh[1], mesh[2]
  local _vproj, _fproj = {}, {}
  for v in all(_vertices) do
    add(_vproj, project_point(cam, v))
  end
  local c = 0
  for f in all(_faces) do
    local x0, y0, z0, d0 = unpack(_vproj[f[1]])
    local x1, y1, z1, d1 = unpack(_vproj[f[2]])
    local x2, y2, z2, d2 = unpack(_vproj[f[3]])
    local key, visible = (d0 + d1 + d2) / 3, min(z0, min(z1, z2)) > 0
    --local key, visible = sqr_norm({0.1 * ((x0 + x1 + x2) / 3 - 64), 0.1 * ((y0 + y1 + y2) / 3 - 64), (z0 + z1 + z2) / 3}), min(z0, min(z1, z2)) > 0
    if (visible) then
      add(_fproj, {key, x0, y0, x1, y1, x2, y2, c + 2})
      c = (c + 1) % 14
    end
  end

  sort(_fproj)

  for f in all(_fproj) do
    local _, x0, y0, x1, y1, x2, y2, c = unpack(f)
    triangle_fill(x0, y0, x1, y1, x2, y2, c, 1)
  end
end

function project_point(cam, pt3d)
  local _t, _r = cam[1], cam[2]
  local x, y, z = unpack(translate(_t, rotate(_r, pt3d)))
  return {64 * x / z + 64, 64 * y / z + 64, 64 / z, sqr_norm({x, y, z})}
end

function sqr_norm(vec)
  local result = 0
  for i=1,#vec do
    result += vec[i] * vec[i]
  end
  return result
end

function rotate(r, pt3d)
  return pt3d
end

function translate(t, pt3d)
  return {pt3d[1] + t[1], pt3d[2] + t[2], pt3d[3] + t[3]}
end

-- sorts list of tables in decreasing order based on first element of each entry
function sort(l)
  local unsorted = true
  while unsorted do
    unsorted = false
    for i=1,#l-1 do
      if l[i+1][1] > l[i][1] then
        l[i], l[i+1] = l[i+1], l[i]
        unsorted = true
      end
    end
  end
end

function draw_viewport()
  window_width = 60
  window_height = 60
  triangle_width = 20
  dash_height = 10
  triangle_fill(0, 0, 0, window_height, triangle_width, window_height, 2)
  triangle_fill(triangle_width + window_width, window_height, 2 * triangle_width + window_width, window_height, 2 * triangle_width + window_width, 0, 2)
  rectfill(0, window_height, 2 * triangle_width + window_width, window_height + dash_height, 2)
  --rect(triangle_width, 0, triangle_width + window_width, window_height, 1)
end

-->8
-- general graphics

function triangle(x0, y0, x1, y1, x2, y2, c)
  line(x0, y0, x1, y1, c)
  line(x2, y2)
  line(x0, y0)
end


function _triangle_fill(x0, y0, x1, y1, x2, y2, c)
  local dya, dyb, dyc = y0 - y1, y0 - y2, y1 - y2
  local xs, ys, xe, ye = x0, y0, x0, y1
  local dxa, dxb, dxc = 0, 0, 0
  if (dya != 0) dxa = (x0 - x1) / dya
  if (dyb != 0) dxb = (x0 - x2) / dyb
  if (dyc != 0) dxc = (x1 - x2) / dyc
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

function triangle_fill(x0, y0, x1, y1, x2, y2, c1, c2)
  local _x0, _y0, _x1, _y1, _x2, _y2 = x0, y0, x1, y1, x2, y2
  if _y0 > _y1 or _y0 > _y2 then
    if (_y0 > _y1) _x0, _y0, _x1, _y1 = _x1, _y1, _x0, _y0
    if (_y0 > _y2) _x0, _y0, _x2, _y2 = _x2, _y2, _x0, _y0
  end
  if (_y1 > _y2) _x1, _y1, _x2, _y2 = _x2, _y2, _x1, _y1
  _triangle_fill(_x0, _y0, _x1, ceil(_y1), _x2, _y2, c1)
  if c2 != nil then
    triangle(_x0, _y0, _x1, ceil(_y1), _x2, _y2, c2)
  end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
