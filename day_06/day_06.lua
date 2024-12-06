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
