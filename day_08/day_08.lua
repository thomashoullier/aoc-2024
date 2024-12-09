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

-- # Part 2
-- The difference with part 1 is not too bad.
-- We only need to iterate over unordered pairs now.
-- For each pair we can find the positions of antinodes
-- which are within the bounds.
-- We just accumulate all of these across all antenna pairs
-- and we're good.

-- Iterator over unordered list pairs
function iter_on_unordered_list_pairs (list)
  local i = 1
  local j = 1
  local n = #list
  return function ()
    j = j + 1
    if j > n then -- go to next i
      i = i + 1
      j = i + 1
    end
    if i < n then
      return list[i], list[j]
    end
  end
end

print("Testing iter_on_unordered_list_pairs")
for pair1, pair2 in iter_on_unordered_list_pairs({1, 2, 3, 4}) do
  print(pair1, pair2)
end

-- Return all of the antinode positions for a pair of antennae
-- which are within the bounds.
function all_antinodes_in_bounds (antenna_1, antenna_2, shape)
  local antinodes = {}
  -- We go in one directin and the other to get all positions
  local vec = utils.sub_vec(antenna_2, antenna_1)
  local i = 0
  local antinode = utils.copy_table(antenna_2)
  -- From antenna 2 to the border:
  while utils.indices_in_matrix(antinode, shape) do
    table.insert(antinodes, antinode)
    antinode = utils.add_vec(antinode, vec)
  end
  -- From antenna 1 to the border:
  antinode = utils.copy_table(antenna_1)
  while utils.indices_in_matrix(antinode, shape) do
    table.insert(antinodes, antinode)
    antinode = utils.sub_vec(antinode, vec)
  end
  return antinodes
end

print("Testing all antinodes generated by two antennae")
ex_A_nodes = all_antinodes_in_bounds({6, 7}, {9,9}, utils.matrix_shape(ex_mat))
for _, node in ipairs(ex_A_nodes) do
  print(table.concat(node, ' '))
end

print("Testing all antinodes generated by two antennae")
ex_A_nodes = all_antinodes_in_bounds({10, 10}, {9,9}, utils.matrix_shape(ex_mat))
for _, node in ipairs(ex_A_nodes) do
  print(table.concat(node, ' '))
end

-- Marking all the antinodes generated with the harmonics rules
function mark_harmonic_antinodes(mat)
  local marked_matrix = utils.copy_matrix(mat)
  local shape = utils.matrix_shape(mat)
  local antenna_types = find_unique_antennae(mat)
  for _, antenna_type in ipairs(antenna_types) do
    local antenna_coords = find_antenna_type_coordinates(mat, antenna_type)
    for antenna_1, antenna_2 in iter_on_unordered_list_pairs(antenna_coords) do
      local antinodes = all_antinodes_in_bounds(antenna_1, antenna_2, shape)
      for _, antinode in ipairs(antinodes) do
        marked_matrix[antinode[1]][antinode[2]] = '#'
      end
    end
  end
  return marked_matrix
end

print("Example marked matrix with harmonics: ")
ex_harmonic_antinodes = mark_harmonic_antinodes(ex_mat)
utils.print_matrix(ex_harmonic_antinodes)
input_harmonic_antinodes = mark_harmonic_antinodes(input_mat)

print("Part 2 example result: ", count_antinodes(ex_harmonic_antinodes))
print("Part 2 result: ", count_antinodes(input_harmonic_antinodes))
