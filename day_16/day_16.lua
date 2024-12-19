-- Day 16
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

input_str = utils.file_to_string("input.txt")
ex_str = "###############\n"
      .. "#.......#....E#\n"
      .. "#.#.###.#.###.#\n"
      .. "#.....#.#...#.#\n"
      .. "#.###.#####.#.#\n"
      .. "#.#.#.......#.#\n"
      .. "#.#.#####.###.#\n"
      .. "#...........#.#\n"
      .. "###.#.#####.#.#\n"
      .. "#...#.....#.#.#\n"
      .. "#.#.#.###.#.#.#\n"
      .. "#.....#...#.#.#\n"
      .. "#.###.#.#.#.#.#\n"
      .. "#S..#.....#...#\n"
      .. "###############\n"
ex2_str = "#################\n"
       .. "#...#...#...#..E#\n"
       .. "#.#.#.#.#.#.#.#.#\n"
       .. "#.#.#.#...#...#.#\n"
       .. "#.#.#.#.###.#.#.#\n"
       .. "#...#.#.#.....#.#\n"
       .. "#.#.#.#.#.#####.#\n"
       .. "#.#...#.#.#.....#\n"
       .. "#.#.#####.#.###.#\n"
       .. "#.#.#.......#...#\n"
       .. "#.#.###.#####.###\n"
       .. "#.#.#...#.....#.#\n"
       .. "#.#.#.#####.###.#\n"
       .. "#.#.#.........#.#\n"
       .. "#.#.#.#########.#\n"
       .. "#S#.............#\n"
       .. "#################\n"

-- # Parsing
input_map = utils.str_to_matrix(input_str)
ex_map = utils.str_to_matrix(ex_str)
ex2_map = utils.str_to_matrix(ex2_str)
print("Example 1:")
utils.print_matrix(ex_map)
print("Example 2:")
utils.print_matrix(ex2_map)

-- # Part 1
-- We can make the following assumptions:
-- 1. A minimal path never crosses itself.
-- 2. At a fork, it never makes sense to turn multiple times before moving.
--    When an empty cell is available on the right, the reindeer turns and
--    moves right, this is a single possible move.
-- 3. We never have to turn back (rotate twice).
-- Thus we just search through all paths, accumulating the moves and marking
-- visited tiles along the way. We compute the scores from the moves.
-- Among all the viable paths, we check what is the minimal score.

REINDEER = 'S'
EMPTY = '.'
WALL = '#'
END = 'E'

-- Find the reindeer starting position.
function find_reindeer (map)
  return utils.matrix_find(map, REINDEER)
end

ex_dims = utils.matrix_shape(ex_map)
print("Example 1 dimensions: ", table.concat(ex_dims, ','))
ex2_dims = utils.matrix_shape(ex2_map)
print("Example 2 dimensions: ", table.concat(ex2_dims, ','))
input_dims = utils.matrix_shape(input_map)
print("Input dimensions: ", table.concat(input_dims, ','))

print("Example 1 reindeer starting position: ",
      utils.position_to_string(find_reindeer(ex_map)))
print("Example 2 reindeer starting position: ",
      utils.position_to_string(find_reindeer(ex2_map)))

print("Cross positions from example 1 reindeer {14,2}: ")
for pos in utils.positions_in_cross({14,2}, ex_dims) do
  print(utils.position_to_string(pos))
end

UP = 1
RIGHT = 2
DOWN = 3
LEFT = 4

TO_LEFT = 5
IN_FRONT = 6
TO_RIGHT = 7
BEHIND = 8

-- Given two direction, say whether the second direction is
-- TO_LEFT, IN_FRONT, TO_RIGHT or BEHIND the first direction.
function relative_direction (dir1, dir2)
  if dir1 == dir2 then
    return IN_FRONT
  elseif dir1 == UP then
    if dir2 == RIGHT then return TO_RIGHT
    elseif dir2 == DOWN then return BEHIND
    else return TO_LEFT -- dir2 == LEFT
    end
  elseif dir1 == RIGHT then
    if dir2 == DOWN then return TO_RIGHT
    elseif dir2 == UP then return TO_LEFT
    else return BEHIND -- dir2 == LEFT
    end
  elseif dir1 == DOWN then
    if dir2 == LEFT then return TO_RIGHT
    elseif dir2 == RIGHT then return TO_LEFT
    else return BEHIND -- dir2 == UP
    end
  else -- dir1 == LEFT
    if dir2 == UP then return TO_RIGHT
    elseif dir2 == DOWN then return TO_LEFT
    else return BEHIND -- dir2 == RIGHT
    end
  end
end

-- Absolute direction from a current direction and a relative one
function absolute_direction_change (absdir, reldir)
  if reldir == TO_RIGHT then
    if absdir == UP then
      return RIGHT
    elseif absdir == RIGHT then
      return DOWN
    elseif absdir == DOWN then
      return LEFT
    elseif absdir == LEFT then
      return UP
    end
  elseif reldir == TO_LEFT then
    if absdir == UP then
      return LEFT
    elseif absdir == RIGHT then
      return UP
    elseif absdir == DOWN then
      return RIGHT
    elseif absdir == LEFT then
      return DOWN
    end
  end
end

-- Iterator the next_position, relative_direction, next_direction
-- Prefer to return a relative direction of IN_FRONT first.
function reindeer_choices (current_position, current_direction, dims)
  local i = -1
  return function ()
    i = i+1
    local next_position = {current_position[1], current_position[2]}
    if i == 0 then -- Return IN_FRONT
      local vec = utils.displacement_vec(current_direction)
      next_position = utils.add_vec(current_position, vec)
      return next_position, IN_FRONT, current_direction
    elseif i == 2 then -- Return TO_RIGHT
      local new_dir = absolute_direction_change(current_direction, TO_RIGHT)
      local vec = utils.displacement_vec(new_dir)
      next_position = utils.add_vec(current_position, vec)
      return next_position, TO_RIGHT, new_dir
    elseif i == 1 then -- Return TO_LEFT
      local new_dir = absolute_direction_change(current_direction, TO_LEFT)
      local vec = utils.displacement_vec(new_dir)
      next_position = utils.add_vec(current_position, vec)
      return next_position, TO_LEFT, new_dir
    end
  end
end

-- Iterator to the positions left, front and right of the current
-- reindeer direction (UP, RIGHT, DOWN, LEFT), their relative direction
-- (TO_LEFT, IN_FRONT, TO_RIGHT), and their absolute direction.
-- {{position, direction} ... }
-- function reindeer_choices (current_position, current_direction, dims)
--   local cross_iter = utils.positions_in_cross(current_position, dims)
--   local next_position = nil
--   local next_direction = nil
--   return function ()
--     next_position, next_direction = cross_iter()
--     local rel_dir = relative_direction(current_direction, next_direction)
--     if rel_dir == BEHIND then
--       next_position, next_direction = cross_iter()
--       rel_dir = relative_direction(current_direction, next_direction)
--     end
--     if next_position and rel_dir and next_direction then
--       return next_position, rel_dir, next_direction
--     end
--   end
-- end

ex_choices = reindeer_choices({14,2}, RIGHT, ex_dims)
print("Reindeer possible moves from {14,2}: ")
for choice_pos, choice_reldir, choice_absdir in ex_choices do
  print("Position: ", utils.position_to_string(choice_pos),
        "relative direction: ", choice_reldir,
        "absolute direction: ", choice_absdir)
end

-- Reindeer moves
ADVANCE = 9
TURN_RIGHT = 10
TURN_LEFT = 11

-- Move to string representation
function move_tostring (move)
  if move == ADVANCE then
    return "ADVANCE"
  elseif move == TURN_RIGHT then
    return "TURN_RIGHT"
  elseif move == TURN_LEFT then
    return "TURN_LEFT"
  end
end

-- Given a relative direction, give the list of moves which
-- must be executed to reach the next position.
function moves_for_reldir (relative_direction)
  if relative_direction == IN_FRONT then
    return {ADVANCE}
  elseif relative_direction == TO_RIGHT then
    return {TURN_RIGHT, ADVANCE}
  elseif relative_direction == TO_LEFT then
    return {TURN_LEFT, ADVANCE}
  end
end

-- Set a position to visited in the visited map
function set_visited (visit_map, next_position, dims)
  local lexi = utils.lex_index(next_position, dims)
  visit_map[lexi] = true
end

-- Was a position previously visited?
function is_visited (visit_map, next_position, dims)
  local lexi = utils.lex_index(next_position, dims)
  if visit_map[lexi] then
    return true
  else
    return false
  end
end

-- Cost of a set of moves
function moves_cost (moves)
  local cost = 0
  for _, move in ipairs(moves) do
    if move == ADVANCE then
      cost = cost + 1
    elseif move == TURN_RIGHT then
      cost = cost + 1000
    elseif move == TURN_LEFT then
      cost = cost + 1000
    end
  end
  return cost
end

-- The successful paths are collected in success_moves
-- {{move1, move2, ...}, {move1, move2, ...}}
function next_step (map, dims, next_position, next_direction,
                    next_moves, visit_map, cost_map,
                    running_cost, minimal_cost, success_visits)
  local next_elem = utils.matrix_el(map, next_position)
  local new_cost = moves_cost(next_moves) + running_cost
  local pos_cost = cost_map[next_position[1]][next_position[2]]
  cost_map[next_position[1]][next_position[2]] = math.min(new_cost, pos_cost)
  if new_cost > minimal_cost[1] or new_cost > pos_cost + 2000 then
    return false
  end
  if next_elem == END then
    print("END found at cost ", new_cost)
    set_visited(visit_map, next_position, dims)
    table.insert(success_visits, {new_cost, utils.copy_table(visit_map)})
    minimal_cost[1] = new_cost
    return true
  elseif next_elem == WALL then
    return false
  elseif (next_elem == EMPTY or next_elem == REINDEER)
    and not is_visited(visit_map, next_position, dims) then
    --print(utils.position_to_string(next_position))
    local choices = reindeer_choices(next_position, next_direction, dims)
    -- for _, move in ipairs(next_moves) do
    --   --table.insert(past_moves, move)
    -- end
    set_visited(visit_map, next_position, dims)
    local moves_to_add = nil
    for choice_pos, choice_reldir, choice_absdir in choices do
      moves_to_add = moves_for_reldir(choice_reldir)
      next_step(map, dims, choice_pos, choice_absdir,
                moves_to_add,
                utils.copy_table(visit_map), cost_map,
                new_cost, minimal_cost, success_visits)
    end
  end
end

-- Search for all paths between start and end which have a chance to be minimal
-- Return the sequence of moves.
function find_paths (map)
  -- Find reindeer
  local start_position = find_reindeer(map)
  local dims = utils.matrix_shape(map)
  -- Set initial direction
  local start_direction = RIGHT
  -- Create the success_moves table and run the search
  local success_visits = {}
  next_step(map, dims, start_position, start_direction,
            {}, {}, utils.full(dims, 1e9), 0, {1e9}, success_visits)
  -- Return success_moves
  return success_visits
end

print("Example search:")
ex_visits = find_paths(ex_map)

-- Find the minimal costs among paths
function minimal_path_cost (paths)
  local min_cost = moves_cost(paths[1])
  for _, path in ipairs(paths) do
    local cost = moves_cost(path)
    min_cost = math.min(min_cost, cost)
  end
  return min_cost
end

-- We have to prune the search in some way, otherwise it takes
-- too long on the input.

print("Example 2 search: ")
ex2_visits = find_paths(ex2_map)
print("Input search: ")
input_visits = find_paths(input_map) -- Takes 1min 12sec

-- # Part 2
-- We change the search to accumulate the successful visited tiles.

-- Find the minimal cost among the saved visits.
function find_minimal_visit_cost (visits)
  local min_cost = 1e9
  for _, visit in ipairs(visits) do
    local cost = visit[1]
    min_cost = math.min(min_cost, cost)
  end
  return min_cost
end

ex_mincost = find_minimal_visit_cost(ex_visits)
print("Example 1 minimal cost: ", ex_mincost)
ex2_mincost = find_minimal_visit_cost(ex2_visits)
print("Example 2 minimal cost: ", ex2_mincost)
input_mincost = find_minimal_visit_cost(input_visits)
print("Part 1 result: ", input_mincost)

-- Filter through all the visit_maps, and return only the unique
-- positions of minimal paths
function filter_visits (visits, mincost)
  local unique_lexis = {}
  for _, visit in ipairs(visits) do
    local cost = visit[1]
    if cost == mincost then
      local lexis = visit[2]
      for k,_ in pairs(lexis) do
        unique_lexis[k] = true
      end
    end
  end
  return unique_lexis
end

ex_unique_lexis = filter_visits(ex_visits, ex_mincost)
print("Example 1 unique tiles: ", utils.count_keys(ex_unique_lexis))
ex2_unique_lexis = filter_visits(ex2_visits, ex2_mincost)
print("Example 2 unique tiles: ", utils.count_keys(ex2_unique_lexis))
input_unique_lexis = filter_visits(input_visits, input_mincost)
print("Part 2 result: ", utils.count_keys(input_unique_lexis))
