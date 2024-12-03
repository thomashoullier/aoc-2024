-- Day 03

-- # Input parsing
example_str = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"
file = io.open("input.txt")
input_str = file:read("*a")
file:close()

-- # Part 1
-- Find all the patterns like "mul(2,4)" in the input.
-- Returns an iterator to the muls.
function find_muls (str)
  return string.gmatch(str, "mul%(%d+,%d+%)")
end

-- Collect an iterator to a table
function collect_iter (iter)
  local tab = {}
  for v in iter do
    table.insert(tab, v)
  end
  return tab
end

example_muls = collect_iter(find_muls(example_str))
print(table.concat(example_muls, '\n'))

-- Find the number pair in a mul string
function number_pair (mul)
  local pair = collect_iter(string.gmatch(mul, "%d+"))
  return pair
end

-- Accumulate the multiplication of pairs
function part1_result (str)
  local count = 0
  for mul in find_muls(str) do
    local pair = number_pair(mul)
    count = count + pair[1] * pair[2]
  end
  return count
end

example_part1_result = part1_result(example_str)
print("Part 1 example result: ", example_part1_result)

part1_answer = part1_result(input_str)
print("Part 1 result: ", part1_answer)

-- # Part 2
-- We reprocess the input to match the muls and do, dont.

example_str2 = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"

-- Find the mul and its position in the string.
function find_muls_pos(str)
  return string.gmatch(str, "()(mul%(%d+,%d+%))")
end

function find_dos_pos(str)
  return string.gmatch(str, "()(do%(%))")
end

function find_donts_pos(str)
  return string.gmatch(str, "()(don%'t%(%))")
end

-- Collect all the muls, dos and donts
-- as tuples with their type first, eventual data second.
-- mul: {MUL, {num1, num2}}
-- do: {DO}
-- dont: {DONT}
-- Return the list of tuples sorted by ascending order of position.
MUL = 1
DO = 2
DONT = 3

function collect_muls_do_dont (str)
  local tuples = {}
  for pos, mul in find_muls_pos(str) do
    local pair = number_pair(mul)
    table.insert(tuples, {pos, MUL, pair})
  end
  for pos, doo in find_dos_pos(str) do
    table.insert(tuples, {pos, DO})
  end
  for pos, dont in find_donts_pos(str) do
    table.insert(tuples, {pos, DONT})
  end
  table.sort(tuples, function (tup1, tup2) return tup1[1] < tup2[1] end)
  local tokens = {}
  for i, v in ipairs(tuples) do
    table.remove(v, 1)
    table.insert(tokens, v)
  end
  return tokens
end

example_tuples = collect_muls_do_dont(example_str2)
for i, tup in ipairs(example_tuples) do
  print(tup[1])
end

-- Read the tuple sequence and do the operations accordingly.
function read_sequence (tuples)
  local mul_active_b = true
  local count = 0
  for i, tup in ipairs(tuples) do
    local typ = tup[1]
    if typ == MUL and mul_active_b then
      count = count + tup[2][1] * tup[2][2]
    elseif typ == DO then
      mul_active_b = true
    elseif typ == DONT then
      mul_active_b = false
    end
  end
  return count
end

example_part2_result  = read_sequence(collect_muls_do_dont(example_str2))
print("Part 2 example result: ", example_part2_result)
part2_result = read_sequence(collect_muls_do_dont(input_str))
print("Part 2 result: ", part2_result)
