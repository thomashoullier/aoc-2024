-- Day 23
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

input_str = utils.file_to_string("input.txt")
ex_str = "kh-tc\n"
      .. "qp-kh\n"
      .. "de-cg\n"
      .. "ka-co\n"
      .. "yn-aq\n"
      .. "qp-ub\n"
      .. "cg-tb\n"
      .. "vc-aq\n"
      .. "tb-ka\n"
      .. "wh-tc\n"
      .. "yn-cg\n"
      .. "kh-ub\n"
      .. "ta-co\n"
      .. "de-co\n"
      .. "tc-td\n"
      .. "tb-wq\n"
      .. "wh-td\n"
      .. "ta-ka\n"
      .. "td-qp\n"
      .. "aq-cg\n"
      .. "wq-ub\n"
      .. "ub-vc\n"
      .. "de-ta\n"
      .. "wq-aq\n"
      .. "wq-vc\n"
      .. "wh-yn\n"
      .. "ka-de\n"
      .. "kh-ta\n"
      .. "co-tc\n"
      .. "wh-qp\n"
      .. "tb-vc\n"
      .. "td-yn\n"

-- # Parsing
-- We parse the thing as a sort of graph
-- in a hashmap {computer, {connected computers}}, computers are represented
-- by their string

-- Return the two computers in a line
-- Lines are like: "wh-qp"
function parse_line (str)
  return string.sub(str, 1, 2), string.sub(str, 4,5)
end

ex_comp1, ex_comp2 = parse_line("wh-qp")
print("Example computers in wh-qp: ", ex_comp1, ex_comp2)

-- Add a computer connected in one direction to another computer to the graph
-- Graph is modified in place
function add_computer (comp1, comp2, graph)
  local comp1_node = graph[comp1]
  if comp1_node then -- Add comp2 to the list of computers connected to comp1
    table.insert(graph[comp1], comp2)
  else -- Create the node
    graph[comp1] = {comp2}
  end
end

-- Add two computers linked adirectionnally to the graph
function add_linked_computers (comp1, comp2, graph)
  add_computer(comp1, comp2, graph)
  add_computer(comp2, comp1, graph)
end

-- Parse the input into a graph
function parse_graph(str)
  local graph = {}
  for line in utils.lines(str) do
    local comp1, comp2 = parse_line(line)
    add_linked_computers(comp1, comp2, graph)
  end
  return graph
end

-- Print the graph
function print_graph(graph)
  for comp, linked_comps in pairs(graph) do
    print(comp, ": ", table.concat(linked_comps, ','))
  end
end

ex_graph = parse_graph(ex_str)
print("Example graph: ")
print_graph(ex_graph)
input_graph = parse_graph(input_str)
-- print("Input graph: ")
-- print_graph(input_graph)

-- # Part 1
-- The problem is small enough that we can go through every computer
-- and find all possible loops of size 3. Then we filter for the ones
-- with a computer beginning in t.

-- Compute a key associated to a set of three computers
function compute_loop3_key (comp1, comp2, comp3)
  -- We sort the strings alphabetically and concatenate them, creating our key.
  local tab = {comp1, comp2, comp3}
  table.sort(tab, function (str1, str2) return str1 < str2 end)
  return tab[1] .. tab[2] .. tab[3]
end

ex_loop3_key = compute_loop3_key("ta", "ka", "de")
print("Example key for loop with de,ka,ta: ", ex_loop3_key)

-- Given a starting computer, find all loops of size three.
-- Store it as a key aabbcc in a hashmap.
function find_3loops (graph, start_comp, three_loops)
  local comp1_node = graph[start_comp]
  for _, comp2 in ipairs(comp1_node) do
    if comp2 ~= comp1 then
      local comp2_node = graph[comp2]
      for _, comp3 in ipairs(comp2_node) do
        local comp3_node = graph[comp3]
        for _, comp4 in ipairs(comp3_node) do
          if comp4 == start_comp then
            local loop_key = compute_loop3_key(start_comp, comp2, comp3)
            three_loops[loop_key] = true
          end
        end
      end
    end
  end
end

ex_3loops = {}
find_3loops(ex_graph, "td", ex_3loops)
print("Loops in the example involving td: ")
for k,_ in pairs(ex_3loops) do
  print(k)
end

-- Find all loops with size 3 in the graph.
function find_all_3loops (graph)
  three_loops = {}
  for comp, _ in pairs(graph) do
    find_3loops(graph, comp, three_loops)
  end
  return three_loops
end

ex_3loops = find_all_3loops(ex_graph)
print("All loops of size 3 in the example: ")
for k,_ in pairs(ex_3loops) do
  print(k)
end

-- Find the loops of size three which involve a computer starting with t.
function find_all_3loops_t (graph)
  three_loops = {}
  for comp, _ in pairs(graph) do
    if string.sub(comp, 1, 1) == 't' then
      find_3loops(graph, comp, three_loops)
    end
  end
  return three_loops
end

ex_3loops = find_all_3loops_t(ex_graph)
print("All loops of size 3 with at least one t-computer in the example: ")
for k,_ in pairs(ex_3loops) do
  print(k)
end
print("There are ", utils.table_size(ex_3loops), " such loops in the example.")

input_3loops = find_all_3loops_t(input_graph)
print("Part 1 result: ", utils.table_size(input_3loops))
