-- Day 11
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

-- # Parsing
ex_str = "125 17"
input_str = utils.file_to_string("input.txt")

-- Parse the input into a table of numbers
function parse_input (str)
  local tab = {}
  for char_str in utils.iter_on_separator(str, ' ') do
    table.insert(tab, tonumber(char_str))
  end
  return tab
end

ex_tab = parse_input(ex_str)
print("Example: ", table.concat(ex_tab, ' '))
input_tab = parse_input(input_str)
print("Input: ", table.concat(input_tab, ' '))

-- # Part 1
-- Technically we could solve this without tracking the order of rocks,
-- but since the problem mentions something about their ordering, it is
-- safer to keep it. We implement a doubly-linked list of rocks.

-- A rock is implemented as {left_ref, number, right_ref}.

-- Get the left neighbor of the provided rock.
-- May return nil for the very first rock.
function left (rock)
  return rock[1]
end

function right (rock)
  return rock[3]
end

-- Return the number written on the rock
function num (rock)
  return rock[2]
end

-- Create a new rock
function create_rock (left_rock, num, right_rock)
  return {left_rock, num, right_rock}
end

-- Setters
function set_left (rock, new_left)
  rock[1] = new_left
end

function set_right (rock, new_right)
  rock[3] = new_right
end

function set_num (rock, new_num)
  rock[2] = new_num
end

-- Initialize the doubly-linked list from the sequence of numbers.
function init_rocks (nums)
  local list = {}
  local last_rock = nil
  for _, num in ipairs(nums) do
    local new_rock = create_rock(last_rock, num, nil)
    if last_rock then
      set_right(last_rock, new_rock)
    end
    last_rock = new_rock
    table.insert(list, new_rock)
  end
  return list
end

ex_list = init_rocks(ex_tab)
input_list = init_rocks(input_tab)

-- Iterator to the rocks, left to right
function rocks (first_rock)
  local current_rock = first_rock
  local next_rock = first_rock
  return function ()
    current_rock = next_rock
    if current_rock then
      next_rock = right(current_rock)
    end
    return current_rock
  end
end

print("Rocks list in input: ")
for rock in rocks(input_list[1]) do
  print(num(rock))
end

-- Op: replace rock with one engraved with one
function op_replace_with_one (rock)
  set_num(rock, 1)
end

-- Split a number in two by its digits, return the two numbers
function split_num (num)
  local num_str = tostring(num)
  local n = string.len(num_str)
  local n2 = math.floor(n / 2 + 0.5)
  local first_str = string.sub(num_str, 1, n2)
  local second_str = string.sub(num_str, n2 + 1, n)
  -- tonumber removes the leading zeroes automatically
  return tonumber(first_str), tonumber(second_str)
end

ex_split_left, ex_split_right = split_num(17)
print("Example of splitting 17: ", ex_split_left, ex_split_right)

-- Op: Split the rock into two halves, removing leading zeros and keeping
--     the doubly linked list connected
--     Put the new rock on the *left*, thus allowing the iteration to continue
--     unaltered.
function op_split (rock, list)
  local num_left, num_right = split_num(num(rock))
  local old_left = left(rock)
  local new_left = create_rock(old_left, num_left, rock)
  if old_left then
    set_right(old_left, new_left)
  end
  set_left(rock, new_left)
  set_num(rock, num_right)
  table.insert(list, new_left)
end

-- Op: Multiply by 2024
function op_mul (rock)
  set_num(rock, num(rock) * 2024)
end

-- Find the first rock in the list, from a starting rock
function find_first_rock (start_rock)
  local current_rock = start_rock
  while left(current_rock) do
    current_rock = left(current_rock)
  end
  return current_rock
end

print("First rock in input: ", num(find_first_rock(input_list[3])))

-- Does a number have an even number of digits?
function even_digits (num)
  local num_str = tostring(num)
  local n = string.len(num_str)
  return math.floor(math.fmod(n, 2) + 0.5) == 0
end

print("2345 has an even number of digits? ", even_digits(2345))

-- Process a rock according to the rules
function process_rock (rock, list)
  local cur_num = num(rock)
  if cur_num == 0 then
    op_replace_with_one(rock)
  elseif even_digits(cur_num) then
    op_split(rock, list)
  else
    op_mul(rock)
  end
end

-- Blink once, processing all the rocks
function blink (first_rock, list)
  for rock in rocks(first_rock) do
    process_rock(rock, list)
  end
end

-- Blink n times
function blink_n (first_rock, list, n)
  local first = first_rock
  for i = 1, n do
    first = find_first_rock(first)
    blink(first, list)
    -- Print the rocks for debug
    -- for rock in rocks(find_first_rock(first)) do
    --   io.write(tostring(num(rock)) .. ' ')
    -- end
    -- print() -- newline
  end
end

-- ! Mutate the lists by blinking !
blink_n(ex_list[1], ex_list, 25)
blink_n(input_list[1], input_list, 25)

print("Part 1 example result: ", #ex_list)
print("Part 1 result: ", #input_list)

-- # Part 2
-- Of course. The order did not even matter.
