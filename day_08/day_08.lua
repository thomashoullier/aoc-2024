-- Day 08

-- # Parsing the input
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

ex_str =
   "............\n"
.. "........0...\n"
.. ".....0......\n"
.. ".......0....\n"
.. "....0.......\n"
.. "......A.....\n"
.. "............\n"
.. "............\n"
.. "........A...\n"
.. ".........A..\n"
.. "............\n"
.. "............\n"

ex_mat = utils.str_to_matrix(ex_str)
utils.print_matrix(ex_mat)
input_mat = utils.str_to_matrix(utils.file_to_string("input.txt"))
utils.print_matrix(input_mat)

-- # Part 1
-- We can just loop over the types of antenna, and for each type, loop over
-- every antenna, then loop over every other of its kind, compute the
-- mirror symmetry coordinates of the first antenna by the second antenna,
-- mark an antinode if it is in bounds.
-- Then we simply count all the nodes.

-- Find all of the unique antenna types.
function find_unique_antennae (mat)
  local types = {}
  for elem in utils.iter_on_matrix(mat) do
    if elem ~= '.' then
      types[elem] = true
    end
  end
  local unique_types = {}
  for k, _ in pairs(types) do
    table.insert(unique_types, k)
  end
  return unique_types
end

ex_antenna_types = find_unique_antennae(ex_mat)
print("Example antenna types: ", table.concat(ex_antenna_types, ' '))
input_antenna_types = find_unique_antennae(input_mat)
print("Input antenna types: ", table.concat(input_antenna_types, ' '))

-- Find the coordinates for all antennae of a given type
-- {{i1, j1}, {i2, j2}, ..., {in, jn}}
function find_antenna_type_coordinates (mat, antenna_type)
  local coordinates = {}
  local shape = utils.matrix_shape(mat)
  for i = 1, shape[1] do
    for j = 1, shape[2] do
      local element = mat[i][j]
      if element == antenna_type then
        local coords = {i, j}
        table.insert(coordinates, coords)
      end
    end
  end
  return coordinates
end

ex_A_coords = find_antenna_type_coordinates(ex_mat, 'A')
print("Coordinates of antennae A in example: ")
for _, coords in ipairs(ex_A_coords) do
  print(table.concat(coords, ' '))
end

-- Flip the coordinates of first antenna around the coordinates of the second
-- to find an antinode
function antinode_coordinates (coord1, coord2)
  local delta_i = coord2[1] - coord1[1]
  local delta_j = coord2[2] - coord1[2]
  local i_node = coord2[1] + delta_i
  local j_node = coord2[2] + delta_j
  return {i_node, j_node}
end

ex_A_node = antinode_coordinates({9, 9}, {6, 7})
print("Example antenna A antinode position: ", table.concat(ex_A_node, ' '))

-- Iterator over all possible combinations of ordered pairs in a list.
function iter_on_ordered_list_pairs (list)
  local n = #list
  local i_first = 1
  local i_second = 1
  return function ()
    if i_second <= n then
      i_second = i_second + 1
      -- Skip the current first element
      if i_second == i_first then
        i_second = i_second + 1
      end
    end
    if i_second > n then -- Go to the next first element
      i_first = i_first + 1
      i_second = 1
    end
    if i_first <= n then
      return list[i_first], list[i_second]
    end
  end
end

ex_A_combinations = iter_on_ordered_list_pairs(ex_A_coords)
print("Iterating over all ordered combination of antenna A pairs: ")
for coord1, coord2 in ex_A_combinations do
  print(table.concat(coord1, ' '), " ; ", table.concat(coord2, ' '))
end

-- Mark all the antinode coordinates in a matrix
function mark_antinodes (mat)
  local marked_matrix = utils.copy_matrix(mat)
  local shape = utils.matrix_shape(mat)
  local antenna_types = find_unique_antennae(mat)
  for _, antenna_type in ipairs(antenna_types) do
    local antenna_coords = find_antenna_type_coordinates(mat, antenna_type)
    for antenna_1, antenna_2 in iter_on_ordered_list_pairs(antenna_coords) do
      local antinode = antinode_coordinates(antenna_1, antenna_2)
      -- Mark it in the matrix if it is inside
      if utils.indices_in_matrix(antinode, shape) then
        marked_matrix[antinode[1]][antinode[2]] = '#'
      end
    end
  end
  return marked_matrix
end

print("Example matrix with marked antinodes: ")
ex_mat_antinodes = mark_antinodes(ex_mat)
utils.print_matrix(ex_mat_antinodes)
input_mat_antinodes = mark_antinodes(input_mat)

-- Count the number of antinodes in the matrix.
function count_antinodes(marked_matrix)
  local count = 0
  for elem in utils.iter_on_matrix(marked_matrix) do
    if elem == '#' then
      count = count + 1
    end
  end
  return count
end

print("Part 1 example solution: ", count_antinodes(ex_mat_antinodes))
print("Part 1 solution: ", count_antinodes(input_mat_antinodes))
