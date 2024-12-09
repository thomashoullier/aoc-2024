-- # Parsing the input
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

ex_str = "2333133121414131402"
input_str = utils.file_to_string("input.txt")

print("The input has length: ", string.len(input_str))

-- # Parsing the input
-- We simply read the digits into a long vector
function str_to_digits (str)
  local digits = {}
  for char in utils.str_chars(str) do
    table.insert(digits, tonumber(char))
  end
  return digits
end

ex_digits = str_to_digits(ex_str)
input_digits = str_to_digits(input_str)
utils.print_vector(ex_digits)

-- # Part 1
-- We expand the input sequence into a table with as many elements as there
-- are blocks. We put the file Id in these blocks, and a magic number for
-- empty positions.
-- We then go over the expanded sequence and swap elements until we reach
-- the final sequence.

-- Get the next block type in the compressed sequence:
-- alternate between file and empty space, starting with a file.
FILE = 0
EMPTY = 1
function type_iter ()
  local i = 1
  return function ()
    if i == 1 then i = 0 else i = 1 end
    return i
  end
end

-- Get the next length and type from the sequence
function seq_iter (digits)
  local n = #digits
  local types = type_iter()
  local i = 0
  return function ()
    i = i + 1
    return digits[i], types()
  end
end

-- Get a sequence of file IDs, starting from 0
function file_id_iter ()
  local i = -1
  return function ()
    i = i + 1
    return i
  end
end

-- Expand the digits into the full uncompressed blocks containing
-- either a block ID or EMPTY_BLOCK.
EMPTY_BLOCK = -1
function expand_file_blocks (digits)
  local expanded_blocks = {}
  local compressed_blocks = seq_iter(digits)
  local ids = file_id_iter()
  local elem = 0
  for length, block_type in compressed_blocks do
    if block_type == FILE then
      elem = ids() -- Get a new id
    else -- EMPTY
      elem = EMPTY_BLOCK
    end
    -- Fill blocks according to the length
    for i = 1, length do
      table.insert(expanded_blocks, elem)
    end
  end
  return expanded_blocks
end

ex_expanded_blocks = expand_file_blocks(ex_digits)
print("Example expanded blocks:")
utils.print_vector(ex_expanded_blocks)
input_expanded_blocks = expand_file_blocks(input_digits)

-- Iterator on the next empty block index in the expanded blocks
function empty_block_positions (expanded_blocks)
  local i = 1
  local current_block = expanded_blocks[i]
  local n = #expanded_blocks
  return function ()
    i = i + 1
    if i <= n then
      current_block = expanded_blocks[i]
      while i < n and current_block ~= EMPTY_BLOCK do
        i = i + 1
        current_block = expanded_blocks[i]
      end
      if current_block == EMPTY_BLOCK then
        return i
      end
    end
  end
end

ex_empty_positions = utils.collect_iter(empty_block_positions(ex_expanded_blocks))
print("Successive empty position in expanded sequence: ",
      table.concat(ex_empty_positions, ' '))

-- Iterator on the next file in the expanded blocks, from the end.
function file_block_positions (expanded_blocks)
  local n = #expanded_blocks
  local i = n + 1
  local current_block = expanded_blocks[1]
  return function ()
    i = i - 1
    if i >= 1 then
      current_block = expanded_blocks[i]
      while i > 1 and current_block == EMPTY_BLOCK do
        i = i - 1
        current_block = expanded_blocks[i]
      end
      return i
    end
  end
end

ex_file_positions = utils.collect_iter(file_block_positions(ex_expanded_blocks))
print("Successive file positions in expanded sequence, from the end: ",
      table.concat(ex_file_positions, ' '))

-- Swap two values in a table
function swap (tab, i1, i2)
  local temp = tab[i1]
  tab[i1] = tab[i2]
  tab[i2] = temp
end

-- Go over the full expanded blocks, swap file blocks from the end with
-- empty spaces as long as the indices do not cross. Return the resulting
-- sequences
function swap_blocks (expanded_blocks)
  local blocks = utils.copy_table(expanded_blocks)
  local empty_block_indices = empty_block_positions(blocks)
  local file_block_indices = file_block_positions(blocks)
  local empty_block_index = empty_block_indices()
  local file_block_index = file_block_indices()
  while empty_block_index and file_block_index
    and empty_block_index < file_block_index do
    swap(blocks, empty_block_index, file_block_index)
    empty_block_index = empty_block_indices()
    file_block_index = file_block_indices()
  end
  return blocks
end

ex_swapped_blocks = swap_blocks(ex_expanded_blocks)
input_swapped_blocks = swap_blocks(input_expanded_blocks)

-- Compute the checksum
function checksum (blocks)
  local count = 0
  local i = 1
  local current_block = blocks[i]
  local n = #blocks
  while i < n and current_block ~= EMPTY_BLOCK do
    count = count + (i - 1) * current_block
    i = i + 1
    current_block = blocks[i]
  end
  return count
end

ex_checksum = checksum(ex_swapped_blocks)
input_checksum = checksum(input_swapped_blocks)
print("Part 1 example solution: ", ex_checksum)
print("Part 1 solution: ", input_checksum)
