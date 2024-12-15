-- Day 15
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

input_str = utils.file_to_string("input.txt")
ex_str = "########\n"
      .. "#..O.O.#\n"
      .. "##@.O..#\n"
      .. "#...O..#\n"
      .. "#.#.O..#\n"
      .. "#...O..#\n"
      .. "#......#\n"
      .. "########\n"
      .. "\n"
      .. "<^^>>>vv<v>>v<<\n"

ex_large_str =
   "##########\n"
.. "#..O..O.O#\n"
.. "#......O.#\n"
.. "#.OO..O.O#\n"
.. "#..O@..O.#\n"
.. "#O#..O...#\n"
.. "#O..O..O.#\n"
.. "#.OO.O.OO#\n"
.. "#....O...#\n"
.. "##########\n"
.. "\n"
.. "<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^\n"
.. "vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v\n"
.. "><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<\n"
.. "<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^\n"
.. "^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><\n"
.. "^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^\n"
.. ">^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^\n"
.. "<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>\n"
.. "^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>\n"
.. "v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^\n"


-- # Parsing
-- * The map is represented as a matrix of characters, exactly as in the input.
-- * The chain of moves is put into a table of characters. We define an enum
--   over the characters.

-- Parse the map
WALL = '#'
CRATE = 'O'
ROBOT = '@'
EMPTY = '.'
function parse_map (str)
  return utils.str_to_matrix(str)
end

-- Parse the sequence of characters
UP = '^'
RIGHT = '>'
DOWN = 'v'
LEFT = '<'
function parse_movements (str)
  local movement_table = {}
  for line in utils.lines(str) do
    for char in utils.str_chars(line) do
      table.insert(movement_table, char)
    end
  end
  return movement_table
end

-- Parse the input to a map and a movement sequence
function parse_input (str)
  local blocks = utils.collect_iter(utils.iter_blocks(str))
  local map = parse_map(blocks[1])
  local movements = parse_movements(blocks[2])
  return map, movements
end

ex_map, ex_moves = parse_input(ex_str)
print("Example map:")
utils.print_matrix(ex_map)
print("Example moves: ", table.concat(ex_moves, ''))

ex_large_map, ex_large_moves = parse_input(ex_large_str)
input_map, input_moves = parse_input(input_str)
ex_dims = utils.matrix_shape(ex_map)
input_dims = utils.matrix_shape(input_map)
-- utils.print_matrix(input_map)
-- print(table.concat(input_moves, ''))

-- # Part 1
-- We simply simulate.
-- Position are represented as {i, j} in the matrix.

-- Find the robot position in the map
function find_robot (map)
  local dims = utils.matrix_shape(map)
  for i = 1, dims[1] do
    for j = 1, dims[2] do
      local char = map[i][j]
      if char == ROBOT then
        return {i, j}
      end
    end
  end
end

ex_init_robot = find_robot(ex_map)
print("Initial example robot position: ", table.concat(ex_init_robot, ' '))
input_init_robot = find_robot(input_map)

-- Return the first empty position in the map from the robot's position
-- in a given direction. nil if none found.
function first_empty_position (start_position, map, dims, direction)
  local i = start_position[1]
  local j = start_position[2]
  local cur_char = map[i][j]
  if direction == UP then
    while cur_char ~= EMPTY and cur_char ~= WALL and i > 1 do
      i = i - 1
      cur_char = map[i][j]
    end
  elseif direction == RIGHT then
    while cur_char ~= EMPTY and cur_char ~= WALL and j < dims[2] do
      j = j + 1
      cur_char = map[i][j]
    end
  elseif direction == DOWN then
    while cur_char ~= EMPTY and cur_char ~= WALL and i < dims[1] do
      i = i + 1
      cur_char = map[i][j]
    end
  else -- direction == LEFT
    while cur_char ~= EMPTY and cur_char ~= WALL and j > 1 do
      j = j - 1
      cur_char = map[i][j]
    end
  end
  if cur_char == EMPTY then
      return {i, j}
  end
end

ex_first_empty_right = first_empty_position(ex_init_robot, ex_map, ex_dims,
                                            RIGHT)
print("First empty position to the right of the robot: ",
      table.concat(ex_first_empty_right, ' '))
ex_first_empty_down = first_empty_position({4, 5}, ex_map,
                                           ex_dims, DOWN)
print("First empty position down of {4, 5}: ",
      table.concat(ex_first_empty_down, ' '))

-- Translate everything from the robot's current position to the first
-- empty space in the wanted direction.
-- Operate in place on the map and robot
function translate_from_robot_to_empty (robot, map, dims, direction, first_empty)
  local i = robot[1]
  local j = robot[2]
  local ei = first_empty[1]
  local ej = first_empty[2]
  -- Set the current robot position to empty
  map[i][j] = EMPTY
  if direction == UP then
    for di = ei, i - 2 do -- crates
      map[di][j] = CRATE
    end
    map[i-1][j] = ROBOT
    robot[1] = i-1
  elseif direction == RIGHT then
    for dj = j + 2, ej do
      map[i][dj] = CRATE
    end
    map[i][j+1] = ROBOT
    robot[2] = j+1
  elseif direction == DOWN then
    for di = i + 2, ei do
      map[di][j] = CRATE
    end
    map[i+1][j] = ROBOT
    robot[1] = i+1
  else -- direction == LEFT
    for dj = ej, j - 2 do
      map[i][dj] = CRATE
    end
    map[i][j-1] = ROBOT
    robot[2] = j-1
  end
end

-- Perform one iteration of movement on the map.
function move_robot (robot, map, dims, direction)
  local next_empty = first_empty_position(robot, map, dims, direction)
  if next_empty then -- if we can move
    translate_from_robot_to_empty(robot, map, dims, direction, next_empty)
  end
end

-- Simulate the full robot motion.
-- Return the final map.
function simulate (_map, directions)
  local map = utils.copy_matrix(_map)
  local dims = utils.matrix_shape(map)
  local robot = find_robot(map)
  for _, direction in ipairs(directions) do
    --print("Move ", direction)
    move_robot(robot, map, dims, direction)
    --utils.print_matrix(map)
  end
  return map
end

ex_final_map = simulate(ex_map, ex_moves)
print("Small example final map: ")
utils.print_matrix(ex_final_map)
ex_large_final_map = simulate(ex_large_map, ex_large_moves)
print("Large example final map:")
utils.print_matrix(ex_large_final_map)
input_final_map = simulate(input_map, input_moves)

-- Find all the crates' positions in a map
function find_crates (map)
  local crates = {}
  local dims = utils.matrix_shape(map)
  for pos in utils.iter_matrix_indices(dims) do
    if map[pos[1]][pos[2]] == CRATE then
      table.insert(crates, {pos[1], pos[2]})
    end
  end
  return crates
end

ex_crates = find_crates(ex_final_map)
print("Example crates positions:")
for _, crate in ipairs(ex_crates) do
  print(crate[1], crate[2])
end
ex_large_crates = find_crates(ex_large_final_map)
input_crates = find_crates(input_final_map)

-- Compute the GPS coordinates of a crate
function crate_gps (crate)
  return 100 * (crate[1] - 1) + (crate[2] - 1)
end

-- Compute the sum of all the crates gps coordinates
function total_gps (crates)
  local gps = 0
  for _, crate in ipairs(crates) do
    gps = gps + crate_gps(crate)
  end
  return gps
end

ex_gps = total_gps(ex_crates)
ex_large_gps = total_gps(ex_large_crates)
input_gps = total_gps(input_crates)
print("Example gps: ", ex_gps)
print("Large example gps: ", ex_large_gps)
print("Part 1 result: ", input_gps)
