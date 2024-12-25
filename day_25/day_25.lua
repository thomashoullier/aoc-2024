-- Day 25
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

input_str = utils.file_to_string("input.txt")
ex_str = "#####\n"
      .. ".####\n"
      .. ".####\n"
      .. ".####\n"
      .. ".#.#.\n"
      .. ".#...\n"
      .. ".....\n"
      .. "\n"
      .. "#####\n"
      .. "##.##\n"
      .. ".#.##\n"
      .. "...##\n"
      .. "...#.\n"
      .. "...#.\n"
      .. ".....\n"
      .. "\n"
      .. ".....\n"
      .. "#....\n"
      .. "#....\n"
      .. "#...#\n"
      .. "#.#.#\n"
      .. "#.###\n"
      .. "#####\n"
      .. "\n"
      .. ".....\n"
      .. ".....\n"
      .. "#.#..\n"
      .. "###..\n"
      .. "###.#\n"
      .. "###.#\n"
      .. "#####\n"
      .. "\n"
      .. ".....\n"
      .. ".....\n"
      .. ".....\n"
      .. "#....\n"
      .. "#.#..\n"
      .. "#.#.#\n"
      .. "#####\n"

-- # Parsing

-- Parse a block matrix into a height sequence
function parse_block (mat)
  -- Count the number of # per column, minus one.
  local nr = #mat
  local nc = #(mat[1])
  local heights = {}
  for j = 1, nc do
    local height = -1
    for i = 1, nr do
      if utils.matrix_el(mat, {i, j}) == '#' then
        height = height + 1
      end
    end
    table.insert(heights, height)
  end
  return heights
end

-- Is a given matrix a key or a lock?
-- It seems it is sufficient to look at the first cell
LOCK = 1
KEY = 2
function is_lock_or_key (mat)
  local char = mat[1][1]
  if char == '#' then
    return LOCK
  else -- char == '.'
    return KEY
  end
end

-- Parse the input, return a table of keys and a table of locks
function parse_locks_keys (str)
  local locks = {}
  local keys = {}
  for block in utils.iter_blocks(str) do
    local mat = utils.str_to_matrix(block)
    local mat_type = is_lock_or_key(mat)
    local heights = parse_block(mat)
    if mat_type == LOCK then
      table.insert(locks, heights)
    else -- KEY
      table.insert(keys, heights)
    end
  end
  return locks, keys
end

ex_locks, ex_keys = parse_locks_keys(ex_str)
print("Example locks:")
for _, lock in ipairs(ex_locks) do
  print(table.concat(lock, ','))
end
print("Example keys:")
for _, key in ipairs(ex_keys) do
  print(table.concat(key, ','))
end
input_locks, input_keys = parse_locks_keys(input_str)

-- # Part 1
-- Does the key fit the lock?
function key_fits_lock (lock, key)
  for i = 1, #lock do
    local h = lock[i] + key[i]
    if h > 5 then
      return false
    end
  end
  return true
end

ex_fits = key_fits_lock(ex_locks[1], ex_keys[3])
print("Lock", table.concat(ex_locks[1]), "fits", table.concat(ex_keys[3]), "?",
      ex_fits)

-- Count the number of key/lock matches.
function count_keylock_matches (locks, keys)
  local count = 0
  for _, lock in ipairs(locks) do
    for _, key in ipairs(keys) do
      if key_fits_lock(lock, key) then
        count = count + 1
      end
    end
  end
  return count
end

ex_n_matches = count_keylock_matches(ex_locks, ex_keys)
print("Number of matches in the example: ", ex_n_matches)
input_n_matches = count_keylock_matches(input_locks, input_keys)
print("Part 1 result: ", input_n_matches)
