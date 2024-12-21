-- Day 20
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

input_str = utils.file_to_string("input.txt")
ex_str = "###############\n"
      .. "#...#...#.....#\n"
      .. "#.#.#.#.#.###.#\n"
      .. "#S#...#.#.#...#\n"
      .. "#######.#.#.###\n"
      .. "#######.#.#...#\n"
      .. "#######.#.###.#\n"
      .. "###..E#...#...#\n"
      .. "###.#######.###\n"
      .. "#...###...#...#\n"
      .. "#.#####.#.###.#\n"
      .. "#.#...#.#.#...#\n"
      .. "#.#.#.#.#.#.###\n"
      .. "#...#...#...###\n"
      .. "###############\n"

-- # Parsing
ex_map = utils.str_to_matrix(ex_str)
input_map = utils.str_to_matrix(input_str)
print("Example map:")
utils.print_matrix(ex_map)

ex_start = utils.matrix_find(ex_map, 'S')
print("Example start: ", table.concat(ex_start, ','))
input_start = utils.matrix_find(input_map, 'S')

-- # Part1
-- We can pre-compute the time it takes to reach any cell in the track by
-- not cheating. Then we can follow the track, and check in every direction
-- whether we can cheat and how much time it will save.

-- Fill a map of the cost to reach any point on the track without cheating
-- Iteration step
function cost_map_iter (map, dims, position, cost_map, cost)
  if cost_map[position[1]][position[2]] >= 0 then
    return -- Skip already visited places
  end
  local cell = utils.matrix_el(map, position)
  if cell == '#' then
    return -- Skip walls
  end
  if cell == '.' or cell == 'E' or cell == 'S' then
    cost_map[position[1]][position[2]] = cost
    for next_position in utils.positions_in_cross(position, dims) do
      cost_map_iter(map, dims, next_position, cost_map, cost + 1)
    end
  end
end

-- Compute the cost map associated with the track
-- also return all the nominal positions in the track
function compute_cost_map (map, start)
  local dims = utils.matrix_shape(map)
  local cost_map = utils.full(dims, -1)
  cost_map_iter(map, dims, start, cost_map, 0)
  return cost_map
end

ex_costs = compute_cost_map(ex_map, ex_start)
print("Example track cost matrix: ")
for _, row in ipairs(ex_costs) do
  print(table.concat(row, ', '))
end
input_costs = compute_cost_map(input_map, input_start)

-- * A cheat always takes two picoseconds to take.
-- * A cheat only makes sense when we go straight through a wall
--   in any of the four direction, and when the cell on the other
--   side is empty.

-- Iterator to all two positions in a straight line which stay in bounds.
function two_positions (map, dims, position)
  local i = position[1]
  local j = position[2]
  local nrows = dims[1]
  local ncols = dims[2]
  local tried_position = 0
  return function ()
    while tried_position < 4 do
      tried_position = tried_position + 1
      if tried_position == 1 and i-2 >= 1 then
        return {i-1, j}, {i-2, j}
      elseif tried_position == 2 and j+2 <= ncols then
        return {i, j+1}, {i, j+2}
      elseif tried_position == 3 and i+2 <= nrows then
        return {i+1, j}, {i+2, j}
      elseif tried_position == 4 and j-2 >= 1 then
        return {i, j-1}, {i, j-2}
      end
    end
  end
end

-- Iterator to all the positions on which we end up after a valid cheat.
function cheat_positions (map, dims, position)
  local cross_lines_iter = two_positions(map, dims, position)
  return function()
    local pos1, pos2 = cross_lines_iter()
    while pos1 do
      if pos1 then
        local cell1 = utils.matrix_el(map, pos1)
        local cell2 = utils.matrix_el(map, pos2)
        if cell1 == '#' and cell2 ~= '#' then -- we have a valid cheat
          return pos2
        end
      end
      pos1, pos2 = cross_lines_iter()
    end
  end
end

ex_dims = utils.matrix_shape(ex_map)
print("Example cross lines positions from {14, 10}")
for pos1, pos2 in two_positions(ex_map, ex_dims, {14,10}) do
  print("pos1: ", table.concat(pos1, ','),
        "pos2: ", table.concat(pos2, ','))
end

ex_cheat_positions = cheat_positions(ex_map, ex_dims, {14, 10})
print("Example cheat positions from {14,10}")
for pos in ex_cheat_positions do
  print(table.concat(pos, ','))
end

-- Return the next empty track position.
function track_positions_iter (map, dims, position, visited_map)
  for next_position in utils.positions_in_cross(position, dims) do
    if not utils.matrix_el(visited_map, next_position) then
      local cell = utils.matrix_el(map, next_position)
      if cell ~= '#' then
        visited_map[next_position[1]][next_position[2]] = true
        return next_position
      end
    end
  end
end

-- Iterator to all nominal track positions in sequence.
function track_positions (map, dims, start)
  local visited_map = utils.full(dims, false)
  local position = start
  local start_b = true
  return function ()
    if start_b then -- Return includes the start
      start_b = false
      return position
    end
    position = track_positions_iter(map, dims, position, visited_map)
    if position then
      return position
    end
  end
end

ex_track_positions_iter = track_positions(ex_map, ex_dims, ex_start)
-- print("Example nominal positions in the track:")
-- for pos in ex_track_positions_iter do
--   print(table.concat(pos, ','))
-- end

-- For every nominal position in the track, we look at all available
-- cheat, and we count how much time it saves. Return the list of gains.
function evaluate_cheats (map, dims, start, costs)
  local cheat_counts = {}
  for nom_pos in track_positions(map, dims, start) do
    local cur_cost = utils.matrix_el(costs, nom_pos)
    for cheat_pos in cheat_positions(map, dims, nom_pos) do
      local cheat_pos_cost = utils.matrix_el(costs, cheat_pos)
      local cheat_gain = cheat_pos_cost - cur_cost - 2
      if cheat_counts [cheat_gain] then
        cheat_counts[cheat_gain] = cheat_counts[cheat_gain] + 1
      else
        cheat_counts[cheat_gain] = 1
      end
    end
  end
  return cheat_counts
end

ex_cheat_counts = evaluate_cheats(ex_map, ex_dims, ex_start, ex_costs)
print("Counts of cheats in the example: ")
for k, v in pairs(ex_cheat_counts) do
  if k > 0 then
    print(v, "cheats which save", k, "picosec")
  end
end
input_dims = utils.matrix_shape(input_map)
input_cheat_counts = evaluate_cheats(input_map, input_dims,
                                     input_start, input_costs)

-- Count the number of cheats which save at least 100
function count_cheats_100 (cheat_counts)
  local count = 0
  for save, num in pairs(cheat_counts) do
    if save >= 100 then
      count = count + num
    end
  end
  return count
end

part1_res = count_cheats_100(input_cheat_counts)
print("Part 1 result: ", part1_res)
