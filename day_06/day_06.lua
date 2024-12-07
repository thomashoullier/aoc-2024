-- Day 06
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

-- # Parsing the input
example_str =
              "....#.....\n"
           .. ".........#\n"
           .. "..........\n"
           .. "..#.......\n"
           .. ".......#..\n"
           .. "..........\n"
           .. ".#..^.....\n"
           .. "........#.\n"
           .. "#.........\n"
           .. "......#...\n"

input_str = utils.file_to_string("input.txt")

example_mat = utils.str_to_matrix(example_str)
utils.print_matrix(example_mat)
input_mat = utils.str_to_matrix(input_str)

-- # Part 1
-- We simply simulate the walk of the guard through the matrix until he
-- exits it, we mark every visited position with an X in the matrix.

-- Direction enum
LEFT = 1
UP = 2
RIGHT = 3
DOWN = 4

-- Get the next direction by turning right
function next_direction (current_direction)
  if current_direction == LEFT then
    return UP
  elseif current_direction == UP then
    return RIGHT
  elseif current_direction == RIGHT then
    return DOWN
  elseif current_direction == DOWN then
    return LEFT
  end
end

-- Get the step vector given the current direction of movement
-- The vector is {Di, Dj} in matrix indices.
function step_vector (direction)
  if direction == LEFT then
    return {0, -1}
  elseif direction == UP then
    return {-1, 0}
  elseif direction == RIGHT then
    return {0, 1}
  elseif direction == DOWN then
    return {1, 0}
  end
end

-- Add two vectors
function vec_add (vec1, vec2)
  local n1 = #vec1
  local n2 = #vec2
  assert(n1 == n2, "vec_add: unequal lengths")
  local added_vec = {}
  for i = 1, n1 do
    table.insert(added_vec, vec1[i] + vec2[i])
  end
  return added_vec
end

-- Is a matrix index inside of the matrix dimensions?
function is_inside (matrix_dims, position)
  local nrows = matrix_dims[1]
  local ncols = matrix_dims[2]
  return (position[1] >= 1) and (position[1] <= nrows)
     and (position[2] >= 1) and (position[2] <= ncols)
end

EXIT = 0
OBSTACLE = 1
CLEAR = 2
-- What is in front of the guard?
function what_is_in_front (matrix, matrix_dims,
                           current_position, current_direction)
  local movement_vector = step_vector(current_direction)
  local next_position = vec_add(current_position, movement_vector)
  if not is_inside(matrix_dims, next_position) then
    return EXIT
  end
  local next_element = matrix[next_position[1]][next_position[2]]
  if next_element == '.' or next_element == 'X' then
    return CLEAR
  elseif next_element == '#' then
    return OBSTACLE
  end
end

-- Mark the current position with an X in the matrix
function mark_position (matrix, position)
  matrix[position[1]][position[2]] = 'X'
end

-- Find the indices of a character in a 2D matrix
function find_in_matrix (matrix, element)
  local i = 0
  for _, row in ipairs(matrix) do
    i = i + 1
    local j = 0
    for _, el in ipairs(row) do
      j = j + 1
      if el == element then
        return {i, j}
      end
    end
  end
end

-- Update the position by a step
function take_step (position, direction)
  local step = step_vector(direction)
  local new_position = vec_add(position, step)
  return new_position
end

-- Simulate the guard walk in the matrix.
-- Return a matrix marked with the positions of the guard.
function simulate_walk (init_matrix)
  local matrix = utils.copy_matrix(init_matrix)
  local matrix_dims = {#matrix, #(matrix[1])}
  local position = find_in_matrix(matrix, '^')
  local direction = UP
  local in_front = what_is_in_front(matrix, matrix_dims, position, direction)
  while true do
    mark_position(matrix, position) -- Mark current position
    -- Turn until not obstructed
    while in_front == OBSTACLE do
      direction = next_direction(direction)
      in_front = what_is_in_front(matrix, matrix_dims, position, direction)
    end
    -- If we are at the exit, finish
    if in_front == EXIT then
      break
    end
    -- Take a step and update what is in front
    position = take_step(position, direction)
    in_front = what_is_in_front(matrix, matrix_dims, position, direction)
  end
  return matrix
end

example_walked_mat = simulate_walk(example_mat)
utils.print_matrix(example_walked_mat)
input_walked_mat = simulate_walk(input_mat)

-- Count the occurences of an element in a 2D matrix.
function count_in_matrix (matrix, elem)
  local count = 0
  for _, row in ipairs(matrix) do
    for _, el in ipairs(row) do
      if el == elem then
        count = count + 1
      end
    end
  end
  return count
end

example_part1_result = count_in_matrix(example_walked_mat, 'X')
print("Part 1 example result: ", example_part1_result)
part1_result = count_in_matrix(input_walked_mat, 'X')
print("Part 1 result: ", part1_result)

-- # Part 2
-- This could be formulated as a graph and we could apply cycle detection,
-- but I don't see how this would really help in the end since we still
-- need to rebuild the graph in part for every new obstacle tested and is
-- thus quite similar.

-- What we can do is walk the tiles, and at each turn or step, try
-- putting an obstacle in front if there isn't already one. Then
-- we simulate the remainder of the walk from this point trying
-- to detect a cycle.
-- A walking cycle is detected if the same tile is entered through
-- the same direction twice.
-- We need to make sure we are not testing the same obstacle position
-- twice

-- Mark the direction at a tile in the matrix
function mark_direction (matrix, position, direction)
  matrix[position[1]][position[2]] = direction
end

EXIT = 0
OBSTACLE = 1
CLEAR = 2
CYCLE = 3
WALKED = 4
-- What is in front of the guard (with cycle detection)?
function what_is_in_front_cyc (matrix, matrix_dims,
                               current_position, current_direction)
  local movement_vector = step_vector(current_direction)
  local next_position = vec_add(current_position, movement_vector)
  if not is_inside(matrix_dims, next_position) then
    return EXIT
  end
  local next_element = matrix[next_position[1]][next_position[2]]
  if next_element == current_direction then
    return CYCLE
  elseif next_element == '#' then
    return OBSTACLE
  elseif next_element == UP or next_element == RIGHT
    or next_element == DOWN or next_element == LEFT then
    return WALKED
  else
    return CLEAR
  end
end

-- Iterate through the matrix: either turn or take a step depending
-- on what is in front. Return CYCLE or EXIT if the walk ends.
function next_walk_iter (matrix, matrix_dims,
                         position, direction_ref)
  local direction = direction_ref[1]
  local in_front = what_is_in_front_cyc(matrix, matrix_dims, position, direction)
  if in_front == CLEAR or in_front == WALKED then -- take a step (in-place)
    local new_position = take_step(position, direction)
    position[1] = new_position[1]
    position[2] = new_position[2]
  elseif in_front == OBSTACLE then -- take a turn (in-place)
    direction_ref[1] = next_direction(direction)
  elseif in_front == EXIT or in_front == CYCLE then
    return in_front
  end
end

-- From some arbitrary starting point, detect whether
-- the walk will be a cycle or an exit.
function walk_cycle_status (old_matrix, matrix_dims,
                            old_position, direction)
  matrix = utils.copy_matrix(old_matrix)
  local end_in_front = false
  local direction_ref = {direction}
  local position = utils.copy_table(old_position)
  local last_position = utils.copy_table(position)
  while not end_in_front do
    --print("cycle check: position: ", position[1], position[2])
    --print("cycle check: last_position: ", last_position[1], last_position[2])
    local direction = direction_ref[1]
    if position[1] ~= last_position[1] or position[2] ~= last_position[2] then
      -- Mark the walking direction in the matrix on new positions.
      -- This is the direction a tile was entered in.
      mark_direction(matrix, position, direction)
      --print("Marked direction: ", direction, " at ", position[1], position[2])
    end
    last_position[1] = position[1]
    last_position[2] = position[2]
    end_in_front = next_walk_iter(matrix, matrix_dims, position, direction_ref)
  end
  return end_in_front
end

example_cycle_str =
   "...#.....\n"
.. "........#\n"
.. ".........\n"
.. "..#......\n"
.. ".......#.\n"
example_cycle_mat = utils.str_to_matrix(example_cycle_str)
utils.print_matrix(example_cycle_mat)
example_cycle_status =
  walk_cycle_status(example_cycle_mat,
                    {#example_cycle_mat, #(example_cycle_mat[1])},
                    {3, 4}, UP)
print("Example cycle status: ", example_cycle_status)

example_exit_status =
  walk_cycle_status(example_cycle_mat,
                    {#example_cycle_mat, #(example_cycle_mat[1])},
                    {5, 3}, UP)
print("Example exit status: ", example_exit_status)

-- Walk the matrix as usual, but try placing blocks in front of the guard
-- at every step or turn (when the tile is not already blocked or already
-- walked on) and check whether the following walk will be a cycle or not.
function count_possible_obstacles (matrix)
  local found_possible_count = 0
  local matrix_dims = {#matrix, #(matrix[1])}
  local position = find_in_matrix(matrix, '^')
  local direction_ref = {UP}
  -- Mark the first tile with direction
  mark_direction(matrix, position, direction_ref[1])
  local in_front = what_is_in_front_cyc(matrix, matrix_dims,
                                        position, direction_ref[1])
  while in_front ~= EXIT do
    -- Try to place an obstacle in front of the guard and
    -- see whether the resulting walk will be a cycle or exit.
    if in_front == CLEAR then
      local next_position = take_step(position, direction_ref[1])
      matrix[next_position[1]][next_position[2]] = '#' -- Place obstacle
      local cycle_status =
        walk_cycle_status(matrix, matrix_dims, position, direction_ref[1])
      --print("cycle_status: ", cycle_status)
      if cycle_status == CYCLE then
        found_possible_count = found_possible_count + 1
      end
      -- Restore the matrix
      matrix[next_position[1]][next_position[2]] = '.'
    end
    -- Advance in the normal walk
    local last_position = utils.copy_table(position)
    next_walk_iter(matrix, matrix_dims, position ,direction_ref)
    if position[1] ~= last_position[1] or position[2] ~= last_position[2] then
      -- Mark the walking direction in the matrix on new positions.
      mark_direction(matrix, position, direction_ref[1])
    end
    last_position[1] = position[1]
    last_position[2] = position[2]
    in_front = what_is_in_front_cyc(matrix, matrix_dims,
                                    position, direction_ref[1])
  end
  utils.print_matrix(matrix)
  return found_possible_count
end

example_part2_result = count_possible_obstacles(example_mat)
print("Example part 2 result: ", example_part2_result)
part2_result = count_possible_obstacles(input_mat) -- Takes roughly 15sec to run
print("Part 2 result: ", part2_result)
