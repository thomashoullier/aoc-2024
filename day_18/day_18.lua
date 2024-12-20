-- Day 18
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

input_str = utils.file_to_string("input.txt")
ex_str = "5,4\n"
      .. "4,2\n"
      .. "4,5\n"
      .. "3,0\n"
      .. "2,1\n"
      .. "6,3\n"
      .. "2,4\n"
      .. "1,5\n"
      .. "0,6\n"
      .. "3,3\n"
      .. "2,6\n"
      .. "5,1\n"
      .. "1,2\n"
      .. "5,5\n"
      .. "2,5\n"
      .. "6,5\n"
      .. "1,4\n"
      .. "0,4\n"
      .. "6,4\n"
      .. "1,1\n"
      .. "6,1\n"
      .. "1,0\n"
      .. "0,5\n"
      .. "1,6\n"
      .. "2,0\n"
input_dims = {71, 71}
ex_dims = {7, 7}
input_map = utils.full(input_dims, '.')
ex_map = utils.full(ex_dims, '.')

ex_start = {1, 1}
ex_stop = {7, 7}
ex_map[ex_stop[1]][ex_stop[2]] = 'E'

input_start = {1, 1}
input_stop = {71, 71}
input_map[input_stop[1]][input_stop[2]] = 'E'

-- # Parsing

-- Parse the byte positions (use 1-index)
function parse_bytes (str)
  local positions = {}
  for line in utils.lines(str) do
    local row = {}
    for int in utils.integers(line) do
      local index = tonumber(int) + 1
      table.insert(row, index)
    end
    -- Put the Y index as i, X as j
    local temp = row[1]
    row[1] = row[2]
    row[2] = temp
    table.insert(positions, row)
  end
  return positions
end

ex_positions = parse_bytes(ex_str)
print("Example positions: ")
for _, pos in ipairs(ex_positions) do
  print(pos[1], pos[2])
end
input_positions = parse_bytes(input_str)

-- # Part 1
-- No worries here.

-- Return the map obtained after dropping n bytes on it.
function drop_bytes (_map, byte_positions, n_bytes)
  local map = utils.copy_matrix(_map)
  for ibyte = 1, n_bytes do
    local pos = byte_positions[ibyte]
    map[pos[1]][pos[2]] = '#'
  end
  return map
end

ex_cmap = drop_bytes(ex_map, ex_positions, 12)
print("Corrupted example map: ")
utils.print_matrix(ex_cmap)
input_cmap = drop_bytes(input_map, input_positions, 1024)
print("Corrupted input map: ")
utils.print_matrix(input_cmap)

-- We do something similar to what we did for the reindeer.
-- We prune the paths by storing the minimal cost in a matrix.
function positions_in_cross (position, dims)
  local i = position[1]
  local j = position[2]
  local nrows = dims[1]
  local ncols = dims[2]
  local tried_position = -1
  local rand_position = math.random(4) - 1
  return function ()
    while tried_position < 4 do
      tried_position = tried_position + 1
      if (tried_position + rand_position) % 4 == 0 and i-1 >= 1 then
        return {i-1, j}, tried_position -- UP
      elseif (tried_position + rand_position) % 4 == 1 and j+1 <= ncols then
        return {i, j+1}, tried_position -- RIGHT
      elseif (tried_position + rand_position) % 4 == 2 and i+1 <= nrows then
        return {i+1, j}, tried_position -- DOWN
      elseif j-1 >= 1 then
        return {i, j-1}, tried_position -- LEFT
      end
    end
  end
end

function search_iter (map, dims, cur_pos, cur_cost,
                      cost_matrix, minimal_cost, visited_matrix)
  if cur_cost >= minimal_cost[1] then
    return false
  end
  local cell = utils.matrix_el(map, cur_pos)
  if cell == '#' then
    return false
  end
  local cell_cost = utils.matrix_el(cost_matrix, cur_pos)
  if cur_cost >= cell_cost then
    return false
  end
  cost_matrix[cur_pos[1]][cur_pos[2]] = math.min(cell_cost, cur_cost)
  if cell == 'E' then
    print("HAHA")
    minimal_cost[1] = math.min(minimal_cost[1], cur_cost)
    return true
  end
  visited_matrix[cur_pos[1]][cur_pos[2]] = 'O'
  print(cur_cost, "Current minimum: ", minimal_cost[1])
  utils.print_matrix(visited_matrix)
  -- Else we continue searching
  for next_pos in positions_in_cross(cur_pos, dims) do
    search_iter(map, dims, next_pos, cur_cost + 1, cost_matrix, minimal_cost,
                visited_matrix)
  end
end

function search_minimal_cost (map, start_pos)
  local dims = utils.matrix_shape(map)
  local mincost_a_priori = 500
  local cost_matrix = utils.full(dims, mincost_a_priori)
  local visited_matrix = utils.copy_matrix(map)
  search_iter(map, dims, start_pos, 0, cost_matrix, {mincost_a_priori},
              visited_matrix)
  -- The minimal cost is then just what is stored in the end cell.
  return utils.matrix_el(cost_matrix, dims)
end

--ex_mincost = search_minimal_cost(ex_cmap, ex_start)
--print("Example minimal cost: ", ex_mincost)
--input_mincost = search_minimal_cost(input_cmap, input_start)
--print("Part 1 result: ", input_mincost) -- Takes some minutes to run.

-- # Part 2
-- We can flood the map for every byte that falls and see whether the
-- end is reached at all. No need to count cost anymore.

-- Iteration of the search for the exit.
function search_exit_iter (map, dims, cur_pos, visited_matrix, exit_reached)
  if exit_reached[1] then -- Exit was already reached, stop.
    return true
  end
  if utils.matrix_el(visited_matrix, cur_pos) == 'O' then
    return false
  end
  local cell = utils.matrix_el(map, cur_pos)
  if cell == '#' then
    return false
  end
  visited_matrix[cur_pos[1]][cur_pos[2]] = 'O'
  if cell == 'E' then
    exit_reached[1] = true
    return true
  end
  -- Else we continue searching
  for next_pos in utils.positions_in_cross(cur_pos, dims) do
    search_exit_iter(map, dims, next_pos, visited_matrix, exit_reached)
  end
end

-- For a given map, check whether the exit is reachable at all.
function is_exit_reachable (map)
  local dims = utils.matrix_shape(map)
  local visited_matrix = utils.copy_matrix(map)
  local exit_reached = {false}
  local start_pos = {1, 1}
  search_exit_iter(map, dims, start_pos, visited_matrix, exit_reached)
  return exit_reached[1]
end

ex_reached = is_exit_reachable(ex_cmap)
print("Original example map, exit can be reached? ", ex_reached)
ex_blocked_map = drop_bytes(ex_map, ex_positions, 21)
ex_blocked = is_exit_reachable(ex_blocked_map)
utils.print_matrix(ex_blocked_map)
print("Example blocked map, exit can be reached? ", ex_blocked)

-- Find the coordinates of the first byte to block the map
function first_blocking_byte (clear_map, bytes, start_nbyte)
  for nbyte = start_nbyte, #bytes  do
    local corrupted_map = drop_bytes(clear_map, bytes, nbyte)
    if not is_exit_reachable(corrupted_map) then
      return bytes[nbyte]
    end
  end
end

-- Convert coordinates back to the original indexing
function convert_position_back (position)
  return {position[2] - 1, position[1] - 1}
end

ex_first_blocking_byte = first_blocking_byte(ex_map, ex_positions, 12)
print("First blocking byte in the example: ",
      table.concat(convert_position_back(ex_first_blocking_byte), ','))
input_first_blocking_byte = first_blocking_byte(input_map, input_positions, 1024)

print("Part 2 result: ",
      table.concat(convert_position_back(input_first_blocking_byte), ','))
