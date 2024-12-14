-- Day 13
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

-- # Parsing
ex_str = "Button A: X+94, Y+34\n"
      .. "Button B: X+22, Y+67\n"
      .. "Prize: X=8400, Y=5400\n"
      .. "\n"
      .. "Button A: X+26, Y+66\n"
      .. "Button B: X+67, Y+21\n"
      .. "Prize: X=12748, Y=12176\n"
      .. "\n"
      .. "Button A: X+17, Y+86\n"
      .. "Button B: X+84, Y+37\n"
      .. "Prize: X=7870, Y=6450\n"
      .. "\n"
      .. "Button A: X+69, Y+23\n"
      .. "Button B: X+27, Y+71\n"
      .. "Prize: X=18641, Y=10279\n"
input_str = utils.file_to_string("input.txt")

-- Parse the input block into {xa, ya, xb, yb, tx, ty}
function parse_block (str)
  local values = {}
  for line in utils.lines(str) do
    for int in utils.integers(line) do
      table.insert(values, int)
    end
  end
  return values
end

-- print("Example blocks:")
-- for block in utils.iter_blocks(ex_str) do
--   print(block)
--   print(table.concat(parse_block(block), ' '))
-- end

function parse_input (str)
  local problems = {}
  for block in utils.iter_blocks(str) do
    table.insert(problems, parse_block(block))
  end
  return problems
end

ex_problems = parse_input(ex_str)
input_problems = parse_input(input_str)

print("Example problems: ")
for _, problem in ipairs(ex_problems) do
  print(table.concat(problem, ' '))
end

-- # Part 1
-- Let, for a single machine:
-- * xa, ya the shifts operated by pressing button A.
-- * xb, yb the shifts operated by pressing button B.
-- * tx, ty the prize position.
-- * pa, pb the number of times A and B were pressed.
-- It costs 3 tokens to press A, 1 token to press B.
-- The button may not be pressed more than 100 times each.
--
-- The minimal number of tokens it takes to win at a machine is:
-- min(3.pa + 1.pb) such that
-- | tx = xa.pa + xb.pb
-- | ty = ya.pa + yb.pb
-- | pa <= 100
-- | pb <= 100
-- Let:
-- A = (xa xb)
--     (ya yb)
-- x = (pa)
--     (pb)
-- b = (tx)
--     (ty)
-- The conditions may be reexpressed as:
-- | A.x = b
-- | |x|inf <= 100

-- A.x = b is a system of linear Diophantine equations.
-- Let's just do the inverse on real numbers and check if the result
-- is close enough to an integer:
-- x = A-1 . b

print("Matrix inverse: ")
ex_A = {{4, 7}, {2, 6}}
ex_invA = utils.matrix_22_inverse(ex_A)
utils.print_matrix(ex_invA)

ex2_A = {{94, 22}, {34, 67}}
ex2_invA = utils.matrix_22_inverse(ex2_A)
utils.print_matrix(ex2_invA)
ex2_x = utils.matrix_22_vec_mul(ex2_invA, {8400, 5400})
print("Example (pa,pb): ", table.concat(ex2_x, ' '))

ex3_A = {{26, 67}, {66, 21}}
ex3_invA = utils.matrix_22_inverse(ex3_A)
utils.print_matrix(ex3_invA)
ex3_x = utils.matrix_22_vec_mul(ex3_invA, {12748, 12176})
print("Example (pa,pb): ", table.concat(ex3_x, ' '))

print("1.1 close to integer?", utils.close_to_int(1.1, 1e-10))

-- Check a problem solution (pa, pb) for: close to integer? less than 100 each
-- Return the integer solution if it is right.
function check_solution (presses)
  local tol = 1e-10
  local is_sol = utils.close_to_int(presses[1], tol)
    and utils.close_to_int(presses[2], tol)
    and presses[1] <= 101
    and presses[2] <= 101
  if is_sol then
    return {math.floor(presses[1] + 0.5),
            math.floor(presses[2] + 0.5)}
  end
end

-- Solve a problem, return the valid solution if it exists.
function solve_problem (problem)
  local A = {{problem[1], problem[3]}, {problem[2], problem[4]}}
  local b = {problem[5], problem[6]}
  local A_inv = utils.matrix_22_inverse(A)
  local x = utils.matrix_22_vec_mul(A_inv, b)
  local checked_solution = check_solution(x)
  if checked_solution then
    return checked_solution
  end
end

ex_first_solution = solve_problem(ex_problems[1])
print("Solve first example problem: ",
      table.concat(ex_first_solution, ' '))

-- Solve all problems, return the valid solutions
function solve_problems (problems)
  local solutions = {}
  for _, problem in ipairs(problems) do
    local solution = solve_problem(problem)
    if solution then
      table.insert(solutions, solution)
    end
  end
  return solutions
end

ex_solutions = solve_problems(ex_problems)
print("Example solutions: ")
for _, sol in ipairs(ex_solutions) do
  print(table.concat(sol, ', '))
end
input_solutions = solve_problems(input_problems)

-- Compute the cost of a solution
function solution_cost (solution)
  local A_cost = 3
  local B_cost = 1
  return A_cost * solution[1] + B_cost * solution[2]
end

-- Compute the cost of all solutions
function solutions_cost(solutions)
  local cost = 0
  for _, sol in ipairs(solutions) do
    cost = cost + solution_cost(sol)
  end
  return cost
end

ex_part1_result = solutions_cost(ex_solutions)
print("Example part 1 result: ", ex_part1_result)
input_part1_result = solutions_cost(input_solutions)
print("Part 1 result: ", input_part1_result)

ex_large = 10000000018641
print(ex_large)
