-- Day 12

package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

-- # Parsing
ex_str = "RRRRIICCFF\n"
      .. "RRRRIICCCF\n"
      .. "VVRRRCCFFF\n"
      .. "VVRCCCJFFF\n"
      .. "VVVVCJJCFE\n"
      .. "VVIVCCJJEE\n"
      .. "VVIIICJJEE\n"
      .. "MIIIIIJJEE\n"
      .. "MIIISIJEEE\n"
      .. "MMMISSJEEE\n"
input_str = utils.file_to_string("input.txt")

ex_mat = utils.str_to_matrix(ex_str)
input_mat = utils.str_to_matrix(input_str)

print("Example input: ")
utils.print_matrix(ex_mat)

-- # Part 1
-- We can design an iterator over all the positions in a contiguous region.
-- Then we go over the whole matrix, marking newly found regions by a
-- unique number.
-- Once we have this, we iterate again over each unique region to get
-- their area and perimeter.

ex_dims = utils.matrix_shape(ex_mat)

-- Give all possible up/down/left/right positions from a starting
-- point, staying within the matrix bounds.
function neighbors (position, dims)
  local neigh_positions = {}
  local i = position[1]
  local j = position[2]
  if i > 1 then -- Return up
    table.insert(neigh_positions, {i-1, j})
  end
  if j > 1 then -- Return left
    table.insert(neigh_positions, {i, j-1})
  end
  if i < dims[1] then -- Return down
    table.insert(neigh_positions, {i+1, j})
  end
  if j < dims[2] then -- Return right
    table.insert(neigh_positions, {i, j+1})
  end
  return neigh_positions
end

print("Neighbors of {3, 1}: ")
for _, neigh in ipairs(neighbors({3,1}, ex_dims)) do
  print(table.concat(neigh, ' '))
end

-- Recursive step of visiting all the indices in the map
function region_positions_recur (current_position, matrix, matrix_dims,
                                 visited_positions, region_id)
  -- Mark position as visited.
  visited_positions[utils.lex_index(current_position, matrix_dims)] = true
  -- Try to find matching neighbors
  local neigh_positions = neighbors(current_position, matrix_dims)
  if neigh_positions then
    for _, neigh in ipairs(neigh_positions) do
      if matrix[neigh[1]][neigh[2]] == region_id
        and visited_positions[utils.lex_index(neigh, matrix_dims)] == nil then
        region_positions_recur(neigh, matrix, matrix_dims,
                               visited_positions, region_id)
      end
    end
  end
end

-- Collect all the positions in a contiguous region.
function region_positions (start_position, matrix, matrix_dims)
  local region_id = matrix[start_position[1]][start_position[2]]
  local visited_positions = {} -- Hashmap of all already visited indices.
  region_positions_recur(start_position, matrix, matrix_dims,
                         visited_positions, region_id)
  -- Convert the lexicographic indices back to indices
  local positions = {}
  for lexi, _ in pairs(visited_positions) do
    table.insert(positions, utils.lex_to_index(lexi, matrix_dims))
  end
  return positions
end

ex_R_region = region_positions({1,1}, ex_mat, ex_dims)
print("Example R region indices: ")
for _, pos in ipairs(ex_R_region) do
  print(table.concat(pos, ' '))
end

ex_E_region = region_positions({5,10}, ex_mat, ex_dims)
print("Example E region indices: ")
for _, pos in ipairs(ex_E_region) do
  print(table.concat(pos, ' '))
end

-- Compute the perimeter of a given position
function position_perimeter (position, matrix, matrix_dims, region_id)
  local neighs = neighbors(position, matrix_dims)
  local perimeter = 4 - #neighs -- The border of the matrix counts as perimeter
  -- Every neighbor which is not of the same type is an additional perimeter.
  for _, neigh in ipairs(neighs) do
    if matrix[neigh[1]][neigh[2]] ~= region_id then
      perimeter = perimeter + 1
    end
  end
  return perimeter
end

ex_Rcell_perimeter = position_perimeter({4, 3}, ex_mat, ex_dims, 'R')
print("Example R {4,3} cell perimeter: ", ex_Rcell_perimeter)

-- Go over a region and compute its area and perimeter,
-- while marking visited cells in a matrix mask.
function compute_region_area_perimeter (start, matrix, matrix_dims, visited_mask)
  local region_id = matrix[start[1]][start[2]]
  local area = 0
  local perimeter = 0
  for _, cell in ipairs(region_positions(start, matrix, matrix_dims)) do
    visited_mask[cell[1]][cell[2]] = 1
    area = area + 1
    perimeter = perimeter + position_perimeter(cell, matrix, matrix_dims,
                                               region_id)
  end
  return area, perimeter
end

ex_R_area, ex_R_perimeter = compute_region_area_perimeter({1,1}, ex_mat, ex_dims,
  utils.copy_matrix(ex_mat))
print("Example R, area: ", ex_R_area, "perimeter: ", ex_R_perimeter)

-- Now go over the full matrix, finding cells from new regions, and
-- getting their id, area and perimeters {id, area, perimeter}.
function compute_all_area_perimeter (matrix)
  local matrix_dims = utils.matrix_shape(matrix)
  local visited_mask = utils.zeros(matrix_dims)
  local area_perims = {}
  for position in utils.iter_matrix_indices(matrix_dims) do
    if visited_mask[position[1]][position[2]] == 0 then -- not yet visited
      -- print("position: ", position[1], position[2])
      -- utils.print_matrix(visited_mask)
      local region_id = matrix[position[1]][position[2]]
      local area, perimeter =
        compute_region_area_perimeter(position, matrix,
                                      matrix_dims, visited_mask)
      -- print(area, perimeter)
      table.insert(area_perims, {region_id, area, perimeter})
    end
  end
  return area_perims
end

ex_area_perimeter = compute_all_area_perimeter(ex_mat)
print("Example regions id, area, perimeter: ")
for _, tab in ipairs(ex_area_perimeter) do
  print(table.concat(tab, ' '))
end

input_area_perimeter = compute_all_area_perimeter(input_mat)

-- compute the cost from the lists of area and perimeter
function compute_cost (area_perimeter_list)
  local cost = 0
  for _, region in ipairs(area_perimeter_list) do
    cost = cost + region[2] * region[3]
  end
  return cost
end

print("Part 1 example result: ", compute_cost(ex_area_perimeter))
print("Part 1 result: ", compute_cost(input_area_perimeter))
