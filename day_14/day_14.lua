-- Day 14
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

ex_str = "p=0,4 v=3,-3\n"
      .. "p=6,3 v=-1,-3\n"
      .. "p=10,3 v=-1,2\n"
      .. "p=2,0 v=2,-1\n"
      .. "p=0,0 v=1,3\n"
      .. "p=3,0 v=-2,-2\n"
      .. "p=7,6 v=-1,-3\n"
      .. "p=3,0 v=-1,-2\n"
      .. "p=9,3 v=2,3\n"
      .. "p=7,3 v=-1,2\n"
      .. "p=2,4 v=2,-3\n"
      .. "p=9,5 v=-3,-3\n"
input_str = utils.file_to_string("input.txt")
ex_dims = {7, 11}
input_dims = {103, 101}

-- # Parsing
-- A position is represented as {i, j} in *1-based* indexing
-- A velocity as {vi, vj}
-- A robot input is represented as {position, velocity}

-- Parse a robot
function parse_robot (line)
  local ints = utils.collect_iter(utils.integers(line))
  local i = ints[2] + 1
  local j = ints[1] + 1
  local vi = ints[4]
  local vj = ints[3]
  return {{i, j}, {vi, vj}}
end

-- Parse all robots
function parse_input (str)
  local robots = {}
  for line in utils.lines(str) do
    table.insert(robots, parse_robot(line))
  end
  return robots
end

ex_robots = parse_input(ex_str)
print("Example robots:")
for _, robot in ipairs(ex_robots) do
  print("Position: ", robot[1][1], robot[1][2],
        "velocity: ", robot[2][1], robot[2][2])
end
input_robots = parse_input(input_str)

-- # Part 1
-- We simply simulate the robots movement for 100 iterations.

-- Wrap a position around the edges
function wrap_position (index, n)
  -- Convert back to zero-based first
  local new_index = index - 1
  if new_index >= 0 then
    new_index = math.fmod(new_index, n)
    return math.floor(new_index + 0.5) + 1
  elseif new_index < 0 then
    return wrap_position(n - math.abs(new_index) + 1, n)
  end
end

-- Move a robot in a matrix, with wrapping around the edges,
-- by n iterations
function move (robot, matrix_dims, niter)
  local position = robot[1]
  local velocity = robot[2]
  local new_i = position[1] + niter * velocity[1]
  new_i = wrap_position(new_i, matrix_dims[1])
  local new_j = position[2] + niter * velocity[2]
  new_j = wrap_position(new_j, matrix_dims[2])
  return {{new_i, new_j}, velocity}
end

print("Example robot movement: ")
for i = 1, 5 do
  ex_moved = move(ex_robots[11], ex_dims, i)
  print("Moved example robot at iter ", i, ": ", ex_moved[1][1], ex_moved[1][2])
end

print("Move robot 7 one by one:")
for i = 1, 10 do
  ex_moved = move(ex_robots[7], ex_dims, i)
  print("Moved example robot at iter ", i, ": ", ex_moved[1][1], ex_moved[1][2])
end

-- Move all robots for n iterations
function move_all_robots (robots, matrix_dims, niter)
  local moved_robots = {}
  for i = 1, #robots do
    table.insert(moved_robots, move(robots[i], matrix_dims, niter))
  end
  return moved_robots
end

ex_robots_100 = move_all_robots(ex_robots, ex_dims, 100)
input_robots_100 = move_all_robots(input_robots, input_dims, 100)

-- Return the number of robots per tile as a matrix
function n_robots_per_tile (robots, matrix_dims)
  local nrobots = utils.zeros(matrix_dims)
  for _, robot in ipairs(robots) do
    local position = robot[1]
    --print("position: ", table.concat(position, ' '))
    nrobots[position[1]][position[2]] = nrobots[position[1]][position[2]] + 1
  end
  return nrobots
end

ex_robots_count = n_robots_per_tile(ex_robots_100, ex_dims)
utils.print_matrix(ex_robots_count)
input_robots_count = n_robots_per_tile(input_robots_100, input_dims)

-- Count the robots per quadrant (in odd-shape matrix)
-- return the counts in quadrants: {TL, TR, BL, BR}
function count_quadrants (robots_count)
  local dims = utils.matrix_shape(robots_count)
  local TL = 0
  local TR = 0
  local BL = 0
  local BR = 0
  for i = 1, math.floor(dims[1] / 2) do -- TL
    for j = 1, math.floor(dims[2] / 2) do
      TL = TL + robots_count[i][j]
    end
  end
  for i = 1, math.floor(dims[1] / 2) do
    for j = math.ceil(dims[2] / 2) + 1, dims[2] do
      TR = TR + robots_count[i][j]
    end
  end
  for i = math.ceil(dims[1] / 2) + 1, dims[1] do
    for j = 1, math.floor(dims[2] / 2) do
      BL = BL + robots_count[i][j]
    end
  end
  for i = math.ceil(dims[1] / 2) + 1, dims[1] do
    for j = math.ceil(dims[2] / 2) + 1, dims[2] do
      BR = BR + robots_count[i][j]
    end
  end
  return {TL, TR, BL, BR}
end

ex_quadrant_counts = count_quadrants(ex_robots_count)
print("Example robots in quadrants: ", table.concat(ex_quadrant_counts, ' '))
input_quadrant_counts = count_quadrants(input_robots_count)
ex_part1_result = ex_quadrant_counts[1] * ex_quadrant_counts[2]
                * ex_quadrant_counts[3] * ex_quadrant_counts[4]
part1_result = input_quadrant_counts[1] * input_quadrant_counts[2]
  * input_quadrant_counts[3] * input_quadrant_counts[4]

print("Part 1 example result: ", ex_part1_result)
print("Part 1 result: ", part1_result)

-- # Part 2
-- Let's just output the matrix to a text file for every firt iteration and view
-- it.

-- Convert a count matrix to a matrix of characters with
-- a . for empty cells and # for cells with at least one robot.
function to_image_matrix (count_matrix, dims)
  local image_matrix = utils.full(dims, ' ')
  for loc in utils.iter_matrix_indices(dims) do
    if count_matrix[loc[1]][loc[2]] > 0 then
      image_matrix[loc[1]][loc[2]] = '█'
    end
  end
  return image_matrix
end

-- Iterator to image matrices for a problem
function image_matrices (robots, dims)
  local i_iter = 0
  return function ()
    i_iter = i_iter + 1
    local moved_robots = move_all_robots(robots, dims, i_iter)
    local robot_counts = n_robots_per_tile(moved_robots, dims)
    local image_matrix = to_image_matrix(robot_counts, dims)
    return image_matrix
  end
end

print("First few example iterations of robot positions: ")
ex_imgs = image_matrices(ex_robots, ex_dims)
for i = 1, 5 do
  ex_img = ex_imgs()
  print("Image for i = ", i)
  utils.print_matrix(ex_img)
end

print("Iterations on the real input put in file 'imgs.txt'.")
input_imgs = image_matrices(input_robots, input_dims)
file = io.open("imgs.txt", "w")
io.output(file)
io.write("Successive matrix images:\n")
for i = 1, 10000 do
  input_img = input_imgs()
  io.write("Iteration #", i, "\n")
  mat_str = utils.matrix_to_str(input_img)
  io.write(mat_str)
end
-- Saw nothing for the first 300
