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

-- # Part 2
-- We also simulate

ex2_str =
   "#######\n"
.. "#...#.#\n"
.. "#.....#\n"
.. "#..OO@#\n"
.. "#..O..#\n"
.. "#.....#\n"
.. "#######\n"
.. "\n"
.. "<vv<<^^<<^^\n"

LEFT_CRATE = '['
RIGHT_CRATE = ']'

ex2_map, ex2_moves = parse_input(ex2_str)

-- Create a double map from a normal map
function double_map (map)
  local dims = utils.matrix_shape(map)
  local big_dims = {dims[1], 2 * dims[2]}
  local big_map = utils.full(big_dims, 'Z')
  local next_chars = {}
  for pos in utils.iter_matrix_indices(dims) do
    local cur_char =  map[pos[1]][pos[2]]
    if cur_char == EMPTY then
      next_chars = {EMPTY, EMPTY}
    elseif cur_char == WALL then
      next_chars = {WALL, WALL}
    elseif cur_char == CRATE then
      next_chars = {LEFT_CRATE, RIGHT_CRATE}
    else -- ROBOT
      next_chars = {ROBOT, EMPTY}
    end
    big_map[pos[1]][2*pos[2] - 1] = next_chars[1]
    big_map[pos[1]][2*pos[2]] = next_chars[2]
  end
  return big_map
end

ex_double_map = double_map(ex2_map)
ex_large_double_map = double_map(ex_large_map)
input_double_map = double_map(input_map)
print("Example double map:")
utils.print_matrix(ex_double_map)
print("Large example double map:")
utils.print_matrix(ex_large_double_map)

-- What is in front of the position in a given direction.
-- Return element, position:
-- EMPTY if the way is clear
-- WALL if there is a wall
-- LEFT_CRATE or RIGHT_CRATE if there is a crate
-- No need to check for boundaries here.
function in_front_of (position, map, direction)
  local i = position[1]
  local j = position[2]
  if direction ==  UP then
    return map[i-1][j], {i-1, j}
  elseif direction == RIGHT then
    return map[i][j+1], {i, j+1}
  elseif direction == DOWN then
    return map[i+1][j], {i+1, j}
  else -- direction = LEFT
    return map[i][j-1], {i, j-1}
  end
end

-- Return what is in front of an element, including whole crates.
-- Return the list of {element, position}
function in_front_of_element (position, map, direction)
  local element_in_front, front_position = in_front_of(position, map, direction)
  if element_in_front == LEFT_CRATE
    and (direction == UP or direction == DOWN) then
    return {{element_in_front, front_position},
            {RIGHT_CRATE, {front_position[1], front_position[2] + 1}}}
  elseif element_in_front == RIGHT_CRATE
    and (direction == UP or direction == DOWN) then
    return {{element_in_front, front_position},
            {LEFT_CRATE, {front_position[1], front_position[2] - 1}}}
  else
    return {{element_in_front, front_position}}
  end
end

-- Look in a direction from the robot,
-- return whether the path is clear and collect cells to move
-- along the way.
function is_movable(position, map, direction, movables)
  local elements_in_front = in_front_of_element(position, map, direction)
  local element1 = 'Z'
  local element2 = 'Z'
  if #elements_in_front == 1 then
    element1 = elements_in_front[1][1]
    if element1 == WALL then
      return false
    elseif element1 == EMPTY then
      return true
    elseif element1 == LEFT_CRATE or element1 == RIGHT_CRATE then
      table.insert(movables, elements_in_front[1][2])
      return is_movable(elements_in_front[1][2], map, direction, movables)
    end
  else -- double element case
    element1 = elements_in_front[1][1]
    element2 = elements_in_front[2][1]
    if element1 == WALL or element2 == WALL then
      return false
    elseif element1 == EMPTY and element2 == EMPTY then
      return true
    elseif (element1 == LEFT_CRATE or element1 == RIGHT_CRATE)
      and element2 == EMPTY then
      table.insert(movables, elements_in_front[1][2])
      return is_movable(elements_in_front[1][2], map, direction, movables)
    elseif (element2 == LEFT_CRATE or element2 == RIGHT_CRATE)
      and element1 == EMPTY then
      table.insert(movables, elements_in_front[2][2])
      return is_movable(elements_in_front[2][2], map, direction, movables)
    elseif (element1 == LEFT_CRATE or element1 == RIGHT_CRATE)
      and (element2 == LEFT_CRATE or element2 == RIGHT_CRATE) then
      table.insert(movables, elements_in_front[1][2])
      table.insert(movables, elements_in_front[2][2])
      return (is_movable(elements_in_front[1][2], map, direction, movables)
              and is_movable(elements_in_front[2][2], map, direction, movables))
    end
  end
end

ex_large_movables = {}
print("Large example, try to move LEFT from {5, 9}: ",
      is_movable({5, 9}, ex_large_double_map, LEFT, ex_large_movables))
for _, pos in ipairs(ex_large_movables) do
  print("Movable positions: ", table.concat(pos, ' '))
end
ex_large_movables = {}
print("Large example, try to move LEFT from {4, 9}: ",
      is_movable({4, 9}, ex_large_double_map, LEFT, ex_large_movables))
for _, pos in ipairs(ex_large_movables) do
  print("Movable positions: ", table.concat(pos, ' '))
end
ex_large_movables = {}
print("Large example, try to move UP from {3, 7}: ",
      is_movable({3, 7}, ex_large_double_map, UP, ex_large_movables))
for _, pos in ipairs(ex_large_movables) do
  print("Movable positions: ", table.concat(pos, ' '))
end
ex_large_movables = {}
print("Large example, try to move UP from {6, 7}: ",
      is_movable({6, 7}, ex_large_double_map, UP, ex_large_movables))
for _, pos in ipairs(ex_large_movables) do
  print("Movable positions: ", table.concat(pos, ' '))
end

-- Filter for unique positions
-- TODO: filter for unique movable position, a case can be in front of two cases.
function to_unique_indices (positions, dims)
  local unique_indices = {}
  local tab = {}
  for _, position in ipairs(positions) do
    local lexi = utils.lex_index(position, dims)
    tab[lexi] = true
  end
  for k, _ in pairs(tab) do
    local index = utils.lex_to_index(k, dims)
    table.insert(unique_indices, index)
  end
  return unique_indices
end

-- Sort the positions in the inverse of their direction
function sort_positions (positions, direction)
  local sorted_positions = utils.copy_matrix(positions)
  local pred = function (pos1, pos2) return true end
  if direction == LEFT then -- sort left to right
    pred = function (pos1, pos2) return pos1[2] < pos2[2] end
  elseif direction == UP then -- sort up to down
    pred = function (pos1, pos2) return pos1[1] < pos2[1] end
  elseif direction == RIGHT then -- sort right to left
    pred = function (pos1, pos2) return pos1[2] > pos2[2] end
  else -- sort down to up
    pred = function (pos1, pos2) return pos1[1] > pos2[1] end
  end
  table.sort(sorted_positions, pred)
  return sorted_positions
end

-- Update the map by moving the movables in the given direction.
-- We operate in place so we have to be careful about the order of updates.
function update_map (map, dims, movables, direction)
  if direction == UP then
    for _, movable in ipairs(movables) do
      local i = movable[1]
      local j = movable[2]
      map[i-1][j] = map[i][j]
      map[i][j] = EMPTY
    end
  elseif direction == RIGHT then
    for _, movable in ipairs(movables) do
      local i = movable[1]
      local j = movable[2]
      map[i][j+1] = map[i][j]
      map[i][j] = EMPTY
    end
  elseif direction == DOWN then
    for _, movable in ipairs(movables) do
      local i = movable[1]
      local j = movable[2]
      map[i+1][j] = map[i][j]
      map[i][j] = EMPTY
    end
  else -- direction == LEFT
    for _, movable in ipairs(movables) do
      local i = movable[1]
      local j = movable[2]
      map[i][j-1] = map[i][j]
      map[i][j] = EMPTY
    end
  end
end

ex_large_movables = {}
print("Large example, try to move UP from {6, 7}: ",
      is_movable({6, 7}, ex_large_double_map, UP, ex_large_movables))
ex_large_dims = utils.matrix_shape(ex_large_map)
ex_large_movables = to_unique_indices(ex_large_movables, ex_large_dims)
ex_large_movables = sort_positions(ex_large_movables, UP)
for _, pos in ipairs(ex_large_movables) do
  print("Unique, sorted, movable positions: ", table.concat(pos, ' '))
end
ex_large_map_show = utils.copy_matrix(ex_large_double_map)
update_map(ex_large_map_show, ex_large_dims, ex_large_movables, UP)
utils.print_matrix(ex_large_map_show)

-- Move the robot, return the new robot position.
function update_robot (robot, map, dims, direction)
  local i = robot[1]
  local j = robot[2]
  map[i][j] = EMPTY
  if direction == UP then
    i = i-1
  elseif direction == RIGHT then
    j = j+1
  elseif direction == DOWN then
    i = i+1
  else -- LEFT
    j = j-1
  end
  map[i][j] = ROBOT
  return {i, j}
end

-- Perform one iteration on the map.
-- Return the new robot position.
function iter_on_double_map (map, dims, robot, direction)
  local movables = {}
  local can_move = is_movable(robot, map, direction, movables)
  if can_move then
    movables = to_unique_indices(movables, dims)
    movables = sort_positions(movables, direction)
    update_map(map, dims, movables, direction)
    return update_robot(robot, map, dims, direction)
  end
  return robot
end

-- Simulate the full double map
function simulate_double_map(_map, directions)
  local map = utils.copy_matrix(_map)
  local dims = utils.matrix_shape(map)
  local robot = find_robot(map)
  for _, direction in ipairs(directions) do
    --print("Move ", direction)
    robot = iter_on_double_map(map, dims, robot, direction)
    --utils.print_matrix(map)
  end
  return map
end

simulate_double_map(ex_double_map, ex2_moves)
ex_large_final_map = simulate_double_map(ex_large_double_map, ex_large_moves)
print("Large example final double map: ")
utils.print_matrix(ex_large_final_map)
input_final_map = simulate_double_map(input_double_map, input_moves)

-- Find the positions of the left crates
function find_left_crates (map)
  local crates = {}
  local dims = utils.matrix_shape(map)
  for pos in utils.iter_matrix_indices(dims) do
    if map[pos[1]][pos[2]] == LEFT_CRATE then
      table.insert(crates, {pos[1], pos[2]})
    end
  end
  return crates
end

ex_large_crates = find_left_crates(ex_large_final_map)
print("Crates positions: ")
for _, pos in ipairs(ex_large_crates) do
  print(pos[1], pos[2])
end
input_crates = find_left_crates(input_final_map)

ex_large_gps = total_gps(ex_large_crates)
print("Part 2 large example result: ", ex_large_gps)
input_gps = total_gps(input_crates)
print("Part 2 result: ", input_gps)
