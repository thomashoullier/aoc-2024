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

-- # Part 2
-- Be careful that we are not looking for the longest loop here.
-- We are looking for interconnected computers.
-- * Notice that the largest LAN party is necessarily at most as
--   large as the largest list of connected computers.
--   (in our input these lists all have the same length (13))

-- Since the input is already almost in a graphviz format, let's plot it,
-- we may see the answer directly. Sadly this is not readable for the input.

-- For a given starting computer, we can take the list of connected computers.
-- We save this list. Then we go into each connected computer, and see
-- whether they are connected with the others too.
-- We take the list of connected computers for each computer connected to the
-- first, in all these lists, we are looking for the largest powerset set
-- where the intersection of all the lists has maximal cardinality.

-- For our input, there is only 2^13 = 8192 elements in the powerset,
-- per computer.
-- -> But there has to be a simpler alternative.

-- We can look at each connected computer, and see to how many other
-- computers they themselves are also connected. The maximal number
-- indicates the maximum network size necessarily.

-- Intersection of two sets
function set_intersection(set1, set2)
  local inter = {}
  for _, el1 in ipairs(set1) do
    for _, el2 in ipairs(set2) do
      if el1 == el2 then
        table.insert(inter, el1)
      end
    end
  end
  return inter
end

ex_intersect = set_intersection({"ka", "ta", "de", "tc"},
                                {"co", "tb", "ta", "de"})
print("Example intersection of sets: ", table.concat(ex_intersect, ', '))

-- For two connected computers, see how many other connections they share
function n_connections (graph, comp1, comp2)
  local list1 = graph[comp1]
  local list2 = graph[comp2]
  local inter = set_intersection(list1, list2)
  return #inter
end

print("Example:, de and co share ", n_connections(ex_graph, "de", "co"),
      " other connections.")
print("Example:, ub and kh share ", n_connections(ex_graph, "ub", "kh"),
      " other connections.")

-- For a given computer, get the number of connections shared by
-- the connected computers
function all_n_connections (graph, comp)
  local n_conns = {}
  local other_comps = graph[comp]
  for _, c in ipairs(other_comps) do
    table.insert(n_conns, n_connections(graph, comp, c))
  end
  return n_conns
end

print("Example co, number of shared connections: ",
      table.concat(all_n_connections(ex_graph, "co"), ','))

-- Find any member of the LAN.
-- We look for a computer with maximum connectivity.
function find_any_lan_comp (graph)
  for comp, _ in pairs(graph) do
    local n_conns = all_n_connections(graph, comp)
    local max_conn = math.max(table.unpack(n_conns))
    print(comp, max_conn)
  end
end

print("Example graph connectivity: ", find_any_lan_comp(ex_graph))
-- OK this does not work. We much check more connectivities.
-- Back to the superset idea.

-- For each computer, we see how many of the connected computer
-- we can include in the network, such that they are all connected
-- together.
-- We retain this number of included computers.
-- The computer with highest number is part of the largest LAN network.
-- We only need to check supersets of size at least 2, because sets
-- with 1 are necessarily interconnected.

-- Are the provides computers all interconnected?
function are_interconnected(graph, comps)
  local inter = utils.copy_table(comps)
  local ncomps = #comps
  for _, comp in ipairs(comps) do
    local conn_comps = utils.copy_table(graph[comp])
    table.insert(conn_comps, comp)
    inter = set_intersection(inter, conn_comps)
    if utils.table_size(inter) < ncomps then
      return false
    end
  end
  return true
end

print("Example computers co, de, ka, ta interconnected?",
      are_interconnected(ex_graph, {"co", "de", "ka", "ta"}))

print("Example computers co, de, ka, ta, vc interconnected?",
      are_interconnected(ex_graph, {"co", "de", "ka", "ta", "vc"}))

-- Generate the powerset of a table, iterator
function powerset_iter (tab)
  local ntab = #tab
  local nsuper = math.floor(2^ntab + 0.5)
  local i = -1
  return function ()
    i = i + 1
    if i < nsuper then
      local set = {}
      for j = 0, ntab -1 do
        if (i >> j) % 2 == 1 then
          table.insert(set, tab[j+1])
        end
      end
      return set
    end
  end
end

ex_powerset_iter = powerset_iter({1,2,3,4})
print("Example powerset: ")
for set in ex_powerset_iter do
  print(table.concat(set, ','))
end

-- For a given computer, get the largest fully connected network:
function find_largest_network (graph, comp)
  local other_comps = graph[comp]
  local comps_sets = powerset_iter(other_comps)
  local max_net_size = 0
  local max_net = {}
  for set in comps_sets do
    local nset = #set
    if nset >= 2 and nset > max_net_size then
      -- Are they fully connected?
      local net_b = are_interconnected(graph, set)
      if net_b then
        max_net_size = math.max(max_net_size, nset)
        max_net = set
      end
    end
  end
  return max_net
end

ex_co_net = find_largest_network(ex_graph, "co")
print("Example, find the largest network connected to co: ")
print(table.concat(ex_co_net, ', '))

-- Compute the largest network associated to each computer
function all_largest_networks (graph)
  local nmax = 0
  local max_net = {}
  local max_comp = ""
  for comp, _ in pairs(graph) do
    local net = find_largest_network(graph, comp)
    local net_size = #net
    if net_size > nmax then
      nmax = net_size
      max_net = net
      max_comp = comp
    end
  end
  table.insert(max_net, max_comp)
  return max_net
end

ex_max_net = all_largest_networks(ex_graph)
print("Largest network in example: ", table.concat(ex_max_net, ','))

input_max_net = all_largest_networks(input_graph)
print("Largest networks in input: ", table.concat(input_max_net, ','))

-- Sort the computers in the network
function sort_network (comps)
  local net = utils.copy_table(comps)
  table.sort(net, function (s1, s2) return s1 < s2 end)
  return net
end

print("Example sorted net: ", table.concat(sort_network(ex_max_net), ','))
print("Part 2 result: ", table.concat(sort_network(input_max_net), ','))
