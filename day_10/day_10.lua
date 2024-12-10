-- # Parsing
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

ex_str = "89010123\n"
      .. "78121874\n"
      .. "87430965\n"
      .. "96549874\n"
      .. "45678903\n"
      .. "32019012\n"
      .. "01329801\n"
      .. "10456732\n"
input_str = utils.file_to_string("input.txt")

ex_mat = utils.str_to_dig_matrix(ex_str)
input_mat = utils.str_to_dig_matrix(input_str)
utils.print_matrix(ex_mat)

-- # Part 1
-- We just have to recurse through the map, finding the next
-- steps which increase by one exactly, and check if we reach a 9
-- before running out of places to go.

-- We represent positions in the matrix as {i, j}

-- Iterator on the possible next positions in the matrix.
function next_positions (matrix, matrix_dims, current_position)
  local k = 0 -- Index of directions already checked
              -- 1 for up, 2 for up-right,
              -- 3 for up-right-down, 4 for every checked.
  return function ()
    local i = current_position[1]
    local j = current_position[2]
    local h = matrix[i][j]
    if k == 0 then -- Check up next
      k = 1
      if i > 1 and matrix[i-1][j] == h + 1 then
        return {i-1, j}
      end
    end

    if k == 1 then -- Check right next
      k = 2
      if j < matrix_dims[2] and matrix[i][j+1] == h + 1 then
        return {i, j+1}
      end
    end

    if k == 2 then -- Check down next
      k = 3
      if i < matrix_dims[1] and matrix[i+1][j] == h + 1 then
        return {i+1, j}
      end
    end

    if k == 3 then -- Check left next
      k = 4
      if j > 1 and matrix[i][j-1] == h + 1 then
        return {i, j-1}
      end
    end
  end
end

ex_dims = utils.matrix_shape(ex_mat)
input_dims = utils.matrix_shape(input_mat)
ex_next_positions = utils.collect_iter(next_positions(ex_mat, ex_dims, {1, 3}))
print("Example next positions from first trailhead: ")
for _, row in ipairs(ex_next_positions) do
  print(table.concat(row, ' '))
end

-- Lexicographic index of a position in a matrix
function lex_index (position, matrix_dims)
  return (position[1] - 1) * matrix_dims[2] + position[2]
end

print("Lexicographic index of {2, 5} in a matrix of size {4, 10}: ",
      lex_index({2, 5}, {4, 10}))

-- Find the positions of all the nines reached from a given starting
-- position.
-- all_9_positions is keyed by lexicographic index (flattened) of
-- the matrix
function positions_of_9_recur (matrix, matrix_dims,
                               start_position, all_9_positions)
  for next_position in next_positions(matrix, matrix_dims, start_position) do
    if matrix[next_position[1]][next_position[2]] == 9 then
      all_9_positions[lex_index(next_position, matrix_dims)] = 1
    else
      positions_of_9_recur(matrix, matrix_dims, next_position, all_9_positions)
    end
  end
end

function positions_of_9 (matrix, matrix_dims, start_position)
  local all_9_pos = {}
  positions_of_9_recur(matrix, matrix_dims, start_position, all_9_pos)
  return all_9_pos
end

ex_first_9pos = positions_of_9(ex_mat, ex_dims, {1, 3})
print(ex_first_9pos)
print("9 positions for the first trailhead in example: ")
for k, v in pairs(ex_first_9pos) do
  print(k, v)
end

-- Compute the score of a trailhead, the number of unique 9 that
-- are reached from the trailhead.
function trailhead_score (matrix, matrix_dims, trailhead_position)
  local nine_positions = positions_of_9(matrix, matrix_dims, trailhead_position)
  -- Count the kv in the table.
  local count = 0
  for _, _ in pairs(nine_positions) do
    count = count + 1
  end
  return count
end

ex_first_score = trailhead_score(ex_mat, ex_dims, {1, 3})
print("Score of the first trailhead in example: ", ex_first_score)

-- Iterate over successive matrix indices in lexicographic order.
function matrix_indices (matrix_dims)
  local n = matrix_dims[1]
  local m = matrix_dims[2]
  local i = 1
  local j = 0
  return function ()
    j = j + 1
    if j > m then
      j = 1
      i = i + 1
    end
    if i <= n then
      return {i, j}
    end
  end
end

print("Successive matrix indices for size {3, 4}")
for pos in matrix_indices({3,4}) do
  print(pos[1], pos[2])
end


-- Iterate over the trailhead positions in the map in lexicographic order.
function trailhead_positions (matrix, matrix_dims)
  local indices = matrix_indices(matrix_dims)
  return function ()
    local pos = indices()
    while pos and matrix[pos[1]][pos[2]] ~= 0 do
      pos = indices()
    end
    return pos
  end
end

ex_trailhead_positions = utils.collect_iter(trailhead_positions(ex_mat, ex_dims))
print("Trailhead positions in the example: ")
for _, pos in ipairs(ex_trailhead_positions) do
  print(table.concat(pos, ' '))
end

-- Accumulate the scores of all trailheads.
function map_score (matrix)
  local count = 0
  local matrix_dims = utils.matrix_shape(matrix)
  for trailhead_position in trailhead_positions(matrix, matrix_dims) do
    local score = trailhead_score(matrix, matrix_dims, trailhead_position)
    count = count + score
  end
  return count
end

print("Part 1 example result: ", map_score(ex_mat))
print("Part 1 result: ", map_score(input_mat))
