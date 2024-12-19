-- Day 17
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

input_str = utils.file_to_string("input.txt")
ex_str = "Register A: 729\n"
      .. "Register B: 0\n"
      .. "Register C: 0\n"
      .. "\n"
      .. "Program: 0,1,5,4,3,0\n"

-- # Parsing

-- Parse the registers block into the values of {A, B, C}
function parse_registers (str)
  local regs = {}
  for line in utils.lines(str) do
    local ints = utils.collect_iter(utils.integers(line))
    table.insert(regs, tonumber(ints[1]))
  end
  return regs
end

-- Parse the program block into the combined sequence of op_codes
-- and operands.
function parse_program (str)
  local seq = {}
  for int in utils.integers(str) do
    table.insert(seq, tonumber(int))
  end
  return seq
end

-- Parse the input (register block and program block)
function parse_input (str)
  local blocks = utils.iter_blocks(str)
  local reg_block = blocks()
  local prog_block = blocks()
  return parse_registers(reg_block), parse_program(prog_block)
end

ex_regs, ex_prog = parse_input(ex_str)
input_regs, input_prog = parse_input(input_str)
print("Example registers: ", table.concat(ex_regs, ', '),
      " program: ", table.concat(ex_prog, ', '))
print("Input registers: ", table.concat(input_regs, ', '),
      " program: ", table.concat(input_prog, ', '))
print("Input program is of length ", #input_prog)

-- # Part 1
-- Simply simulate. The input is quite short so it might be overkill
-- to not do it by hand, but we have the time.

-- Get and set registers
function get_A (regs)
  return regs[1]
end

function set_A (regs, val)
  regs[1] = val
end

function get_B (regs)
  return regs[2]
end

function set_B (regs, val)
  regs[2] = val
end

function get_C (regs)
  return regs[3]
end

function set_C (regs, val)
  regs[3] = val
end

-- Read an operand as a literal operand
function read_as_literal (operand)
  return operand
end

-- Read an operand as a combo operand
function read_as_combo (operand, regs)
  if operand >= 7 or operand < 0 then
    print("ERROR")
  elseif operand <= 3 then
    return operand
  elseif operand == 4 then
    return get_A(regs)
  elseif operand == 5 then
    return get_B(regs)
  elseif operand == 6 then
    return get_C(regs)
  end
end

OP_ADV = 0
OP_BXL = 1
OP_BST = 2
OP_JNZ = 3
OP_BXC = 4
OP_OUT = 5
OP_BDV = 6
OP_CDV = 7

-- Run the ADV instruction
function run_adv (regs, operand)
  local oper = read_as_combo(operand, regs)
  local num = get_A(regs)
  local denum = 2^oper
  local res = math.floor((num // denum) + 0.5)
  set_A(regs, res)
end

-- Run the BXL instruction
function run_bxl (regs, operand)
  local oper = read_as_literal(operand)
  local b = get_B(regs)
  local res = oper ~ b
  set_B(regs, res)
end

-- Run the BST instruction
function run_bst (regs, operand)
  local oper = read_as_combo(operand, regs)
  local res = oper % 8
  set_B(regs, res)
end

-- Run the JNZ instruction
-- Return whether a jump has occured (true) or not (false)
function run_jnz (regs, operand, inst_ptr)
  if get_A(regs) == 0 then return false end -- Do nothing
  local oper = read_as_literal(operand)
  inst_ptr[1] = oper + 1 -- Offset for lua indexing
  return true
end

-- Run the BXC instruction
function run_bxc (regs, operand)
  local b = get_B(regs)
  local c = get_C(regs)
  local res = b ~ c
  set_B(regs, res)
end

-- Run the OUT instruction
function run_out (regs, operand, outs)
  local oper = read_as_combo(operand, regs)
  local res = oper % 8
  table.insert(outs, res)
end

-- Run the BDV instruction
function run_bdv (regs, operand)
  local oper = read_as_combo(operand, regs)
  local num = get_A(regs)
  local denum = 2^oper
  local res = math.floor((num // denum) + 0.5)
  set_B(regs, res)
end

-- Run the CDV instruction
function run_cdv (regs, operand)
  local oper = read_as_combo(operand, regs)
  local num = get_A(regs)
  local denum = 2^oper
  local res = math.floor((num // denum) + 0.5)
  set_C(regs, res)
end

-- Run the next instruction, return whether a jump has happened.
function run_instruction (op_code, operand, regs, outs, inst_ptr)
  if op_code == OP_ADV then
    run_adv(regs, operand)
  elseif op_code == OP_BXL then
    run_bxl(regs, operand)
  elseif op_code == OP_BST then
    run_bst(regs, operand)
  elseif op_code == OP_JNZ then
    return run_jnz(regs, operand, inst_ptr)
  elseif op_code == OP_BXC then
    run_bxc(regs, operand)
  elseif op_code == OP_OUT then
    run_out(regs, operand, outs)
  elseif op_code == OP_BDV then
    run_bdv(regs, operand)
  elseif op_code == OP_CDV then
    run_cdv(regs, operand)
  end
  return false
end

-- Simulate the computer
function simulate_computer (_regs, program)
  local regs = utils.copy_table(_regs)
  local outs = {}
  local n_prog = #program
  local inst_ptr = {1}
  while inst_ptr[1] <= n_prog - 1 do
    local op_code = program[inst_ptr[1]]
    local operand = program[inst_ptr[1] + 1]
    local jumped_b = run_instruction(op_code, operand, regs, outs, inst_ptr)
    if not jumped_b then -- Jump forward by 2.
      inst_ptr[1] = inst_ptr[1] + 2
    end
  end
  return outs
end

ex_outs = simulate_computer(ex_regs, ex_prog)
print("Example outputs: ", table.concat(ex_outs, ','))
input_outs = simulate_computer(input_regs, input_prog)
print("Part 1 result: ", table.concat(input_outs, ','))

-- # Part 2
-- Try bruteforcing our way through this?

-- Are the outputs identical to the initial program?
function outs_matches_program (outs, program)
  if not outs then return false end
  local n_outs = #outs
  local n_program = #program
  if n_outs ~= n_program then
    return false
  end
  for i = 1, n_outs do
    if outs[i] ~= program[i] then
      return false
    end
  end
  return true
end

-- Simulate the computer, but stop as soon as the output exceeds the
-- program size.
function simulate_computer_withsize (_regs, program)
  local regs = utils.copy_table(_regs)
  local outs = {}
  local n_prog = #program
  local inst_ptr = {1}
  while inst_ptr[1] <= n_prog - 1 do
    local n_outs = #outs
    local op_code = program[inst_ptr[1]]
    local operand = program[inst_ptr[1] + 1]
    local jumped_b = run_instruction(op_code, operand, regs, outs, inst_ptr)
    if n_outs > n_prog then
      return false, nil
    elseif n_outs == 1 and outs[1] ~= program[1] then
      return false, nil
    elseif n_outs == 2 and outs[2] ~= program[2] then
      return false, nil
    end
    if not jumped_b then -- Jump forward by 2.
      inst_ptr[1] = inst_ptr[1] + 2
    end
  end
  return true, outs
end

-- Try every value of A to see whether we get the program as output.
function find_A_value (regs, program, start_A)
  set_A(regs, start_A - 1)
  local is_candidate = false
  local outs = {}
  while not outs_matches_program(outs, program) do
    set_A(regs, get_A(regs) + 1)
    --print("Try A: ", get_A(regs))
    is_candidate, outs = simulate_computer_withsize(regs, program)
  end
  return get_A(regs)
end

ex2_str = "Register A: 2024\n"
       .. "Register B: 0\n"
       .. "Register C: 0\n"
       .. "\n"
       .. "Program: 0,3,5,4,3,0\n"
ex2_regs, ex2_prog = parse_input(ex2_str)
_, ex2_matching_out = simulate_computer_withsize ({117440, 0, 0}, ex2_prog)
print("Matching example output: ", table.concat(ex2_matching_out, ','))

--ex2_A = find_A_value(ex2_regs, ex2_prog)
print("Example found A value: ", ex2_A)

--input_A = find_A_value(input_regs, input_prog, 2^45)
--print("Part 2 result: ", input_A)

-- The result is after 935M

-- Our input is:
-- Register A: 56256477
-- Register B: 0
-- Register C: 0

-- Program: 2,4,1,1,7,5,1,5,0,3,4,3,5,5,3,0

-- The tranlated program is:
-- BST 4, BXL 1, CDV 5, BXL 5, ADV 3, BXC 3, OUT 5, JNZ 0

-- We can see that there is a single jump to the beginning always.
-- This means we halt only if A = 0 at the point.

-- The operations in sequence are:
-- B <- A % 8
-- B <- B XOR 1
-- C <- A // (2^B)
-- B <- B XOR 5
-- A <- A // (2^3) -- Right shift by 3 bits
-- B <- B XOR C
-- O <- B % 8
-- Halt if A = 0

-- The first O is then:
-- O1 = ((((A % 8) XOR 1) XOR 5) XOR (A // 2^((A % 8) XOR 1))) % 8
-- Breaking into bits:
-- * (A % 8) XOR 1 keeps bits 2 and 3 of A, flips the bit 1.
--   XOR 5 flips bit 3, flips back bit 1 to orignal value.
--   The result of (((A % 8) XOR 1) XOR 5) is
--   the first 3 bits of A with MSB flipped.
-- ....

-- The program is 16 long.
-- Given that it halts when A is zero, and that A is right-shifted by 3
-- at every run, we can deduce immediately the length of A to produce
-- 16 outputs. One output is produced per loop.
-- We must run for 16 loops.
-- Therefore A must be at least 2^(15*3) = 2^(45)
-- and at most 2^(16*3) - 1 = 2^(48) - 1.
-- This is too large to bruteforce.

input_outs = simulate_computer({6, 0, 0}, input_prog)
print(table.concat(input_outs, ','))
input_outs = simulate_computer({6 + 8*1, 0, 0}, input_prog)
print(table.concat(input_outs, ','))
input_outs = simulate_computer({4 + 8*1 + 64*5, 0, 0}, input_prog)
print(table.concat(input_outs, ','))
input_outs = simulate_computer(
  {7 + 8*0 + 64*4 + 512*5, 0, 0}, input_prog)
print(table.concat(input_outs, ','))

-- Trying to see whether the answer to the first part was in fact
-- a way to build the output. It seems that no.
input_outs = simulate_computer(
  {4 + 8*1 + 2^(3*2)*5 + 2^(3*3)*3 + 2^(3*4)*1
     + 2^(3*5)*5 + 2^(3*6)*2 + 2^(3*7)*1, 0, 0}, input_prog)
print(table.concat(input_outs, ','))

-- We only influence the last two outputs when changing the last two variables.
-- We could find the answer by optimizing the sequence two by two.

-- Get the multiplier for the bit of given number, starting at 0
function get_multiplier (bit_number)
  return 2^(3*bit_number)
end

-- Optimize over the output to find the coefficients which lead to the
-- answer.
-- There are XX coefficients required to reach the length of the input.

-- Get the value of A given coefficients
function A_value (coefs)
  local A = 0
  for i = 0, #coefs - 1 do
    A = A + get_multiplier(i) * coefs[i+1]
  end
  return A
end

input_outs = simulate_computer(
  {A_value({0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}), 0, 0}, input_prog)
print(table.concat(input_outs, ','), "of length ", #input_outs)

-- We must find the sequence of length 16 which results in the program,
-- we can optimize the variable two by two from the start

-- Compute the output sequence for a given table of coefficients
function coefs_to_out (coefs, prog)
  local A = A_value(coefs)
  return simulate_computer({A, 0, 0}, prog)
end

input_outs = coefs_to_out({0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
  input_prog)
print(table.concat(input_outs, ','), "of length ", #input_outs)

print(table.concat(input_prog, ','))
input_outs = coefs_to_out({0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 2, 3, 5, 4},
  input_prog)
print(table.concat(input_outs, ','), "of length ", #input_outs)

-- It seems we can arrive at the solution by optimizing coefficients from
-- the top one by one. It works for the first few manually.

-- Run the optimization
function optimize (prog)
  local coefs = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
  local out
  for ibit = 1, #coefs do
    local ivar = #coefs - ibit + 1
    local target = prog[ivar]
    for var = 0, 7 do
      coefs[ivar] = var
      out = coefs_to_out(coefs, prog)
      if #out == #prog and out[ivar] == prog[ivar] then
        break
      end
    end
  end
  print("Coefficients found which return out: ", table.concat(out, ','))
  -- Now we have to optimize the last two digits
  for var1 = 0, 7 do
    for var2 = 0, 7 do
      for var3 = 0, 7 do
        coefs[1] = var1
        coefs[2] = var2
        coefs[3] = var3
        out = coefs_to_out(coefs, prog)
        if #out == #prog and out[1] == prog[1] and out[2] == prog[2]
           and out[3] == prog[3] then
          print("HAHA")
        end
      end
    end
  end
  return coefs
end

input_coefs = optimize(input_prog)
print("Input coefficients: ", table.concat(input_coefs, ' '))

print(table.concat(input_prog, ','))
input_outs = coefs_to_out({7, 5, 3, 3, 3, 4, 7, 6, 2, 6, 1, 3, 2, 3, 5, 4},
  input_prog)
print(table.concat(input_outs, ','))

input_A = find_A_value(input_regs, input_prog,
                       A_value({0, 0, 0, 3, 3, 4, 7, 6, 2, 6, 1, 3, 2, 3, 5, 4}))
print("Found value for A: ", string.format("%.0f", input_A))

input_outs = simulate_computer({164542125272765, 0, 0}, input_prog)
print(table.concat(input_outs, ','))
