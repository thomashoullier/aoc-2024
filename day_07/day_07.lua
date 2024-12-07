-- Day 07
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

-- # Parsing input
example_str = "190: 10 19\n"
  .. "3267: 81 40 27\n"
  .. "83: 17 5\n"
  .. "156: 15 6\n"
  .. "7290: 6 8 6 15\n"
  .. "161011: 16 10 13\n"
  .. "192: 17 8 14\n"
  .. "21037: 9 7 18 13\n"
  .. "292: 11 6 16 20\n"

-- Parse an input string line into {test, {numbers}}
function parse_line (str_row)
  local row = {}
  local before_match, after_match = utils.split_on_pattern(str_row, ": ")
  table.insert(row, tonumber(before_match))
  local numbers = {}
  for num_str in utils.iter_on_separator(after_match, " ") do
    table.insert(numbers, tonumber(num_str))
  end
  table.insert(row, numbers)
  return row
end

-- Print a single problem
function print_problem (problem)
  print(problem[1], ": ", table.concat(problem[2], ' '))
end

-- Parse the full input into {{test, {numbers}}, ...}
function parse_input (str)
  local problems = {}
  for line in utils.lines(str) do
    table.insert(problems, parse_line(line))
  end
  return problems
end

example_problems = parse_input(example_str)
print("Example input (parsed): ")
for _, problem in ipairs(example_problems) do
  print_problem(problem)
end
input_problems = parse_input(utils.file_to_string("input.txt"))

-- # Part 1
-- The input sequences are not that long. We can test every combination of
-- operators

-- Find what is the longest sequence in all of the problems.
-- This is just for information.
function longest_sequence (problems)
  local len = 0
  for _, problem in ipairs(problems) do
    len = math.max(len, #(problem[2]))
  end
  return len
end

function smallest_sequence (problems)
  local len = 10000
  for _, problem in ipairs(problems) do
    len = math.min(len, #(problem[2]))
  end
  return len
end

longest_input_sequence = longest_sequence(input_problems)
smallest_input_sequence = smallest_sequence(input_problems)
print("Longest input sequence is ", longest_input_sequence, " numbers long.")
print ("which is only ", 2^(longest_input_sequence -1), " possibilities")
print("Smallest input sequence is ", smallest_input_sequence, " numbers long.")

-- We use a bitmask representation for the operators to use.
-- 0 means addition.
-- 1 means multiplication.
-- In LSB to the right notation: the number 2 gives the bitmask: 0010
-- means applying a sequence of: addition, multiplication, addition, addition
-- in the order the numbers are presented.

-- Given a sequence of number and a bitmask specifying which operators
-- are used, we compute the result of applying the operators to the numbers.
function compute_test (numbers, bitmask)
  local result = numbers[1]
  local bitposition = 1 -- Move a bit 1 over the mask
  for inum = 2, #numbers do
    local num = numbers[inum]
    if (bitmask & bitposition) == bitposition then -- bitwise and finds a multiplication
      result = result * num
    else -- addition
      result = result + num
    end
    bitposition = bitposition << 1 -- Move the 1 bit by one to the MSB.
  end
  return result
end

example_test = compute_test(example_problems[1][2], 1)
print("Example of computing test value: ", example_test)

-- Iterator on all the operator bitmasks for a sequence of n numbers
function iterator_operator_bitmasks (n)
  local bitmask = -1
  local limit = math.floor(2^(n-1) + 0.5)
  return function ()
    bitmask = bitmask + 1
    if bitmask < limit then
      return bitmask
    end
  end
end

-- Test if a given problem has a solution
function problem_has_solution (problem)
  local test_value = problem[1]
  local numbers = problem[2]
  local all_possible_operations = iterator_operator_bitmasks(#numbers)
  for operations in all_possible_operations do
    local result_value = compute_test(numbers, operations)
    if result_value == test_value then
      return true
    end
  end
  return false -- We tried everything and couldn't find the solution.
end

print("# Example problems: ")
for i, problem in ipairs(example_problems) do
  print("Problem ", i, " has solution? ",
        problem_has_solution(example_problems[i]))
end

-- Accumulate the test value of all solved problems
function accumulate_solved_problems (problems)
  local count = 0
  for _, problem in ipairs(problems) do
    if problem_has_solution(problem) then
      count = count + problem[1]
    end
  end
  return count
end

example_part1_result = accumulate_solved_problems(example_problems)
part1_result = accumulate_solved_problems(input_problems)
print("Part 1 example result: ", example_part1_result)
print("Part 1 result: ", part1_result)

-- # Part 2
-- Given the size of the sequences, we can probably still do it
-- in the "dumb" way.

-- Concatenation operator
function concat_operator (num1, num2)
  return tonumber(tostring(num1) .. tostring(num2))
end

-- We now represent a sequence of operations as {op1, op2, ...}
-- with an op either 0 (addition), 1 (multiplication) or 2 (concat)

-- Next possible operation sequence
-- We iterate like {0, 0, 0}, {1, 0, 0}, {2, 0, 0}, {0, 1, 0} ...
-- until {2, 2, 2}
-- Operates in-place, does not check for end.
function next_possible_operations (operations)
  operations[1] = math.fmod(operations[1] + 1, 3)
  if operations[1] == 0 then -- Carry
    local n = #operations
    local i = 2
    while i <= n do
      operations[i] = math.fmod(operations[i] + 1, 3)
      if operations[i] ~= 0 then return
      end
      i = i + 1
    end
  end
end

-- Iterator over all possible operations for sequence of numbers of length n.
function possible_operations (n)
  local operations = {}
  local i_ops = 0
  local n_ops = math.floor(3 ^ (n-1) + 0.5)
  for i = 1, n - 1 do
    table.insert(operations, 2)
  end
  return function ()
    i_ops = i_ops + 1
    if i_ops <= n_ops then
      next_possible_operations(operations)
      return operations
    end
  end
end

print("Possible operations for sequence of 4: ")
for ops in possible_operations(4) do
  print(table.concat(ops, ' '))
end

-- Compute a result given numbers and the new representation for the operations.
function compute_test_with_concat (numbers, operations)
  local result = numbers[1]
  for inum = 2, #numbers do
    local num = numbers[inum]
    local op = operations[inum - 1]
    if op == 0 then -- Addition
      result = result + num
    elseif op == 1 then -- Multiplication
      result = result * num
    else -- op == 2 -- Concatenation
      result = concat_operator(result, num)
    end
  end
  return result
end

print("Example possible result for problem 2: (+, ||)")
ex_prob2_result = compute_test_with_concat (example_problems[2][2],
                                            {0, 2})

-- Whether a given problem has a solution with concatenation included
-- in the possible operations
function problem_has_solution_with_concat (problem)
  local test_value = problem[1]
  local numbers = problem[2]
  for operations in possible_operations(#numbers) do
    local result_value = compute_test_with_concat(numbers, operations)
    if result_value == test_value then
      return true
    end
  end
  return false -- We tried everything and couldn't find the solution.
end

print("Part 2 example problems: ")
for i, problem in ipairs(example_problems) do
  print("Problem ", i, " has solution? ",
        problem_has_solution_with_concat(problem))
end

function accumulate_solved_problems_with_concat (problems)
  local result = 0
  for _, problem in ipairs(problems) do
    if problem_has_solution_with_concat(problem) then
      result = result + problem[1]
    end
  end
  return result
end

example_part2_result = accumulate_solved_problems_with_concat(example_problems)
print("Part 2 example result: ", example_part2_result)
-- Takes 26sec to run
part2_result = accumulate_solved_problems_with_concat(input_problems)
print(part2_result)
