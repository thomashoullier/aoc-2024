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
