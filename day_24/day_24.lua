-- Day 24
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

input_str = utils.file_to_string("input.txt")
ex1_str = "x00: 1\n"
       .. "x01: 1\n"
       .. "x02: 1\n"
       .. "y00: 0\n"
       .. "y01: 1\n"
       .. "y02: 0\n"
       .. "\n"
       .. "x00 AND y00 -> z00\n"
       .. "x01 XOR y01 -> z01\n"
       .. "x02 OR y02 -> z02\n"
ex2_str = "x00: 1\n"
       .. "x01: 0\n"
       .. "x02: 1\n"
       .. "x03: 1\n"
       .. "x04: 0\n"
       .. "y00: 1\n"
       .. "y01: 1\n"
       .. "y02: 1\n"
       .. "y03: 1\n"
       .. "y04: 1\n"
       .. "\n"
       .. "ntg XOR fgs -> mjb\n"
       .. "y02 OR x01 -> tnw\n"
       .. "kwq OR kpj -> z05\n"
       .. "x00 OR x03 -> fst\n"
       .. "tgd XOR rvg -> z01\n"
       .. "vdt OR tnw -> bfw\n"
       .. "bfw AND frj -> z10\n"
       .. "ffh OR nrd -> bqk\n"
       .. "y00 AND y03 -> djm\n"
       .. "y03 OR y00 -> psh\n"
       .. "bqk OR frj -> z08\n"
       .. "tnw OR fst -> frj\n"
       .. "gnj AND tgd -> z11\n"
       .. "bfw XOR mjb -> z00\n"
       .. "x03 OR x00 -> vdt\n"
       .. "gnj AND wpb -> z02\n"
       .. "x04 AND y00 -> kjc\n"
       .. "djm OR pbm -> qhw\n"
       .. "nrd AND vdt -> hwm\n"
       .. "kjc AND fst -> rvg\n"
       .. "y04 OR y02 -> fgs\n"
       .. "y01 AND x02 -> pbm\n"
       .. "ntg OR kjc -> kwq\n"
       .. "psh XOR fgs -> tgd\n"
       .. "qhw XOR tgd -> z09\n"
       .. "pbm OR djm -> kpj\n"
       .. "x03 XOR y03 -> ffh\n"
       .. "x00 XOR y04 -> ntg\n"
       .. "bfw OR bqk -> z06\n"
       .. "nrd XOR fgs -> wpb\n"
       .. "frj XOR qhw -> z04\n"
       .. "bqk OR frj -> z07\n"
       .. "y03 OR x01 -> nrd\n"
       .. "hwm AND bqk -> z03\n"
       .. "tgd XOR rvg -> z12\n"
       .. "tnw OR pbm -> gnj\n"

-- # Parsing
-- The problem is made of WIRES and GATES.
-- Each object is a table with a type id in front: {WIRE, ...}, {GATE, ...}
-- Wires are: {WIRE, *gate_from, {*gate_to1, *gate_to2, ...}, value}
-- Gates are: {GATE, TYPE, {wire_in1, wire_in2}, wire_out}
-- Wires are put in a hashmap keyed by the wire name.
-- Gates are put in a simple numeric table, the references to elements are used.

WIRE = 5
GATE = 6
AND = 7
OR = 8
XOR = 9

-- Parse the initial values of wires. We put them in a hashmap to use later
function parse_wires_init (str)
  local wire_inits = {}
  for line in utils.lines(str) do
    local name = string.sub(line, 1, 3)
    local value = string.sub(line, 6, 6)
    wire_inits[name] = tonumber(value)
  end
  return wire_inits
end

print("test parse_wires_init")
ex_wires_init = parse_wires_init(
   "x00: 1\n"
.. "x01: 1\n"
.. "x02: 1\n"
.. "y00: 0\n"
.. "y01: 1\n"
.. "y02: 0\n")
for name, val in pairs(ex_wires_init) do
  print(name, val)
end

-- Create a new wire
function make_wire ()
  return {WIRE, nil, {}, nil}
end

function wire_set_value (wire, value)
  wire[4] = value
end

function wire_add_gateto (wire, gate_to)
  table.insert(wire[3], gate_to)
end

function wire_set_gatefrom (wire, gate_from)
  wire[2] = gate_from
end

-- Create a new gate
function make_gate(gate_type, wires_in, wire_out)
  return {GATE, gate_type, wires_in, wire_out}
end

-- Parse the gate type
function parse_gate_type (str)
  local type_str = string.gmatch(str, "%u+")()
  if type_str == "AND" then
    return AND
  elseif type_str == "OR" then
    return OR
  elseif type_str == "XOR" then
    return XOR
  end
end

print("parse_gate_type test: ", parse_gate_type("y00 AND y03 -> djm"))

-- Parse the wires going into and out of a gate
function parse_gate_wires (str)
  local wires = string.gmatch(str, "%l+%d*")
  local wire_in1 = wires()
  local wire_in2 = wires()
  local wire_out = wires()
  return wire_in1, wire_in2, wire_out
end

print("parse_gate_wires test: ", parse_gate_wires("y00 AND y03 -> djm"))

-- Parse the gates block. Create the table of gates and the hashmap of
-- wires (initialized to the known values)
function parse_gates (str, wire_inits)
  local wires = {}
  local gates = {}
  for line in utils.lines(str) do
    local gate_type = parse_gate_type(line)
    local wire_in1, wire_in2, wire_out = parse_gate_wires(line)
    local gate = make_gate(gate_type, {wire_in1, wire_in2}, wire_out)
    table.insert(gates, gate)
    -- Create the wires if they do not exist yet
    if wires[wire_in1] then -- add gate to gate_to
      wire_add_gateto(wires[wire_in1], gate)
    else -- create, with eventual initial value
      local wire = make_wire()
      if wire_inits[wire_in1] then
        wire_set_value(wire, wire_inits[wire_in1])
      end
      wire_add_gateto(wire, gate)
      wires[wire_in1] = wire
    end
    if wires[wire_in2] then -- add gate to gate_to
      wire_add_gateto(wires[wire_in2], gate)
    else -- create, with eventual initial value
      local wire = make_wire()
      if wire_inits[wire_in2] then
        wire_set_value(wire, wire_inits[wire_in2])
      end
      wire_add_gateto(wire, gate)
      wires[wire_in2] = wire
    end
    -- Creat output wire, it cannot exist yet, and it cannot have a value yet
    local wire = make_wire()
    wire_set_gatefrom(wire, gate)
    wires[wire_out] = wire
  end
  return wires, gates
end

function parse_input (str)
  local blocks = utils.iter_blocks(str)
  local wires_block = blocks()
  local wire_inits = parse_wires_init(wires_block)
  local gates_block = blocks()
  local wires, gates = parse_gates(gates_block, wire_inits)
  return wires, gates
end

-- Print a gate
function gate_tostring(gate)
  local gate_type_str = ""
  local gate_type = gate[2]
  if gate_type == AND then
    gate_type_str = "AND"
  elseif gate_type == OR then
    gate_type_str = "OR"
  elseif gate_type == XOR then
    gate_type_str = "XOR"
  end
  local wires_in = gate[3]
  return "GATE " .. wires_in[1] .. " " .. gate_type_str .. " " .. wires_in[2]
      .. " -> " .. gate[4]
end

-- Print the graph from the perspective of wires
function print_wires (wires)
  for name, wire in pairs(wires) do
    local value = wire[4]
    local gate_from = wire[2]
    local gate_from_str = ""
    if gate_from then
      gate_from_str = gate_tostring(gate_from)
    end
    local gates_to = wire[3]
    local gates_to_strings = {}
    for _, gate in ipairs(gates_to) do
      table.insert(gates_to_strings, gate_tostring(gate))
    end
    print(name, value, "from: ", gate_from_str,
          "to: ", table.unpack(gates_to_strings))
  end
end

-- Print the gates
function print_gates(gates)
  for _, gate in ipairs(gates) do
    print(gate_tostring(gate))
  end
end

ex1_wires, ex1_gates = parse_input(ex1_str)
print_wires(ex1_wires)
print_gates(ex1_gates)

-- # Part 1
-- We start by identifying the leaves which can be computed.
-- We maintain this set of gates ready to be computed.
-- Any time we produce an output, we check the gates on the other side
-- of the wire if they are ready and add them to the set if they are.

-- Find the gates which are ready to compute their output.
function find_ready_gates (gates, wires)
  local ready_gates = {}
  for _, gate in ipairs(gates) do
    local wires_in = gate[3]
    local wire1 = wires[wires_in[1]]
    local wire2 = wires[wires_in[2]]
    local wire_out = wires[gate[4]]
    if wire1[4] and wire2[4] and (not wire_out[4])then
      table.insert(ready_gates, gate)
    end
  end
  return ready_gates
end

ex1_ready_gates = find_ready_gates(ex1_gates, ex1_wires)
print("test find_ready_gates:")
print_gates(ex1_ready_gates)

-- Compute the result for a ready gate.
function execute_ready_gate (gate, wires)
  local wires_in = gate[3]
  local wire1 = wires[wires_in[1]]
  local wire2 = wires[wires_in[2]]
  local val1 = wire1[4]
  local val2 = wire2[4]
  local gate_type = gate[2]
  local out_val = nil
  if gate_type == AND then
    out_val = val1 & val2
  elseif gate_type == OR then
    out_val = val1 | val2
  elseif gate_type == XOR then
    out_val = val1 ~ val2
  end
  local wire_out = gate[4]
  wire_set_value(wires[wire_out], out_val)
end

-- We can just simulate by going over every gate at every iteration.
-- The problem is not that large. IN PLACE.
function simulate_circuit (gates, wires)
  local ready_gates = find_ready_gates(gates, wires)
  while #ready_gates > 0 do
    for _, gate in ipairs(ready_gates) do
      execute_ready_gate(gate, wires)
    end
    ready_gates = find_ready_gates(gates, wires)
  end
end

simulate_circuit(ex1_gates, ex1_wires)
print_wires(ex1_wires)

-- Convert a table of bits with LSB first to a decimal number
function binary_to_decimal (bits)
  local mul = 1
  local num = 0
  for _, bit in ipairs(bits) do
    num = num + mul * bit
    mul = mul * 2
  end
  return num
end

print("test binary_to_decimal: ", binary_to_decimal({0, 0, 1}))

-- Read the output wires as a binary sequence
function read_output_wires (wires)
  local out_wires = {}
  for name, wire in pairs(wires) do
    if string.sub(name, 1, 1) == 'z' then
      local value = wire[4]
      table.insert(out_wires, {name, value})
    end
  end
  table.sort(out_wires, function (w1, w2) return w1[1] < w2[1] end)
  local out_bits = {}
  for _, w in ipairs(out_wires) do
    table.insert(out_bits, w[2])
  end
  return binary_to_decimal(out_bits)
end

print("Ex1 result: ", read_output_wires(ex1_wires))

print("Running example 2: ")
ex2_wires, ex2_gates = parse_input(ex2_str)
simulate_circuit(ex2_gates, ex2_wires)
print("result: ", read_output_wires(ex2_wires))

print("Running the input: ")
input_wires, input_gates = parse_input(input_str)
simulate_circuit(input_gates, input_wires)
print("Part 1 result: ", read_output_wires(input_wires))

-- # Part 2
-- Let's try plotting the graph. There must be some structure visually.
-- Treat each gate as a node.

-- Name the gates, in the GATE field
function name_gates (gates)
  local i = 0
  for _, gate in ipairs(gates) do
    gate[1] = 'g' .. tostring(i)
    i = i + 1
  end
end

name_gates(ex1_gates)
name_gates(ex2_gates)
name_gates(input_gates)
print(ex1_gates[1][1])

-- Get a string for the gate relation in the graph.
function gate_graph_string (gate, wires)
  local wire1_n = gate[3][1]
  local wire2_n = gate[3][2]
  local wire_out_n = gate[4]
  local wire1 = wires[wire1_n]
  local wire2 = wires[wire2_n]
  local wire_out = wires[wire_out_n]
  -- We check if there is a gate at the end of wires,
  -- if there isn't we just put the name of the wire in the graph.
  local in1_node = wire1_n
  local in2_node = wire2_n
  local out_node = wire_out_n
  -- Color the outnode
  local out_node_color = ""
  if string.sub(out_node,1,1) == 'z' then
    out_node_color = "red"
  else
    out_node_color = "black"
  end
  -- Determine the color based on gate type
  local gate_type = gate[2]
  local fillcolor = ""
  if gate_type == AND then
    fillcolor = "red"
  elseif gate_type == OR then
    fillcolor = "blue"
  elseif gate_type == XOR then
    fillcolor = "green"
  end
  return "{"..in1_node..","..in2_node.."}->{"..gate[1]..
    "[style=filled,fillcolor=\""..fillcolor.."\"]}"..
    "->".."{"..out_node.."[color=\""..out_node_color.."\"]".."}"
end

ex_graph_str = gate_graph_string(ex1_gates[2], ex1_wires)
print(ex_graph_str)

-- Get a complete string representing the circuit for graphviz
function circuit_graph (named_gates, wires)
  local str = "strict digraph G {\nrankdir=\"BT\"\n"
  for _, gate in ipairs(named_gates) do
    str = str..gate_graph_string(gate, wires).."\n"
  end
  return str .. "}\n"
end

print("Example 1 graphviz:")
ex1_graph_str = circuit_graph(ex1_gates, ex1_wires)
print(ex1_graph_str)
file = io.open("ex1_circuit.gv", "w")
io.output(file)
io.write(ex1_graph_str)
io.close(file)

print("Example 2 graphviz:")
ex2_graph_str = circuit_graph(ex2_gates, ex2_wires)
file = io.open("ex2_circuit.gv", "w")
io.output(file)
io.write(ex2_graph_str)
io.close(file)

print("Input graphviz:")
input_graph_str = circuit_graph(input_gates, input_wires)
file = io.open("circuit.gv", "w")
io.output(file)
io.write(input_graph_str)
io.close(file)

-- Going by eye we can see the discrepancies:
-- 1. g65 is wrong, it is in the place of an AND
--    -- We swap dtk and vgs
-- 2. g168 is wrong, the z21 comes out of it when it should come out of a XOR
--    -- We swap z21 and shh
-- 3. g165 is wrong, the z33 comes out of it when it should come out of a XOR.
--    -- We swap z33 and dqr (maybe?)
-- 4. g206 is wrong, the z39 comes out of it when it should come out of a XOR.
--    -- We swap z39 and pfw

-- dqr,dtk,pfw,shh,vgs,z21,z33,z39
