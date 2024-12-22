-- Day 21
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

input_str = utils.file_to_string("input.txt")
ex_str = "029A\n"
      .. "980A\n"
      .. "179A\n"
      .. "456A\n"
      .. "379A\n"

-- # Parsing
-- Parse a single code to a table of characters
function parse_code (str)
  local chars = {}
  for char in utils.str_chars(str) do
    table.insert(chars, char)
  end
  return chars
end

-- Parse the input codes
function parse_codes (str)
  local codes = {}
  for line in utils.lines(str) do
    table.insert(codes, parse_code(line))
  end
  return codes
end

ex_codes = parse_codes(ex_str)
print("Example codes:")
utils.print_matrix(ex_codes)
input_codes = parse_codes (input_str)
print("Input codes:")
utils.print_matrix(input_codes)

-- # Part1
-- For a current and target position on the keyboards, we can get
-- an optimal move sequence.
-- We have to taken into account the gap of course.
-- We have to take into account that it is shorter to move
-- up, right, down, left in order.

-- Grid positions are counted from {1, 1} at the top left.

-- Position in grid of a given key on the keypad
function pos_in_keypad (key)
  if key == '0' then
    return {4, 2}
  elseif key == '1' then
    return {3, 1}
  elseif key == '2' then
    return {3, 2}
  elseif key == '3' then
    return {3, 3}
  elseif key == '4' then
    return {2, 1}
  elseif key == '5' then
    return {2, 2}
  elseif key == '6' then
    return {2, 3}
  elseif key == '7' then
    return {1, 1}
  elseif key == '8' then
    return {1, 2}
  elseif key == '9' then
    return {1, 3}
  elseif key == 'A' then
    return {4, 3}
  end
end

-- Position in grid of a given key on the dirpad
function pos_in_dirpad (key)
  if key == '<' then
    return {2, 1}
  elseif key == '^' then
    return {1, 2}
  elseif key == 'v' then
    return {2, 2}
  elseif key == '>' then
    return {2, 3}
  elseif key == 'A' then
    return {1, 3}
  end
end

-- Convert a delta position to the required movements needed
-- in straight lines. There are two possibilities, give
-- the first one with up/down movement first, second one
-- with left/right movement first.
function delta_to_moves (delta)
  local vert_delta = delta[1]
  local hor_delta = delta[2]
  local n_vert = math.abs(vert_delta)
  local n_hor = math.abs(hor_delta)
  local ver_moves = {}
  local hor_moves = {}
  if vert_delta < 0 then
    ver_moves = utils.vec_full(n_vert, '^')
  else
    ver_moves = utils.vec_full(n_vert, 'v')
  end
  if hor_delta < 0 then
    hor_moves = utils.vec_full(n_hor, '<')
  else
    hor_moves = utils.vec_full(n_hor, '>')
  end
  local ver_first = utils.concat(ver_moves, hor_moves)
  ver_first = utils.concat(ver_first, {'A'})
  local hor_first = utils.concat(hor_moves, ver_moves)
  hor_first = utils.concat(hor_first, {'A'})
  return ver_first, hor_first
end

print("Moves from position {4, 3} to {2, 1}")
ex_move1, ex_move2 = delta_to_moves(utils.sub_vec({2,1}, {4,3}))
print(table.concat(ex_move1), table.concat(ex_move2))

-- We can start by making iterators to all the straightest
-- paths from a given button to a target button.
-- Do this for the keypad and the dirpad separately.
-- TODO: do not return both moves if it is only one straight line.
function to_pos_keypad (cur_pos, tar_pos)
  local delta = utils.sub_vec(tar_pos, cur_pos)
  local ver_first, hor_first = delta_to_moves(delta)
  if delta[1] == 0 or delta[2] == 0 then
    return {ver_first}
  end
  -- Omit the hor-first or ver-first depending on the positions.
  if cur_pos[2] == 1 and tar_pos[1] == 4 then -- Omit the ver-first
    return {hor_first}
  elseif cur_pos[1] == 4 and tar_pos[2] == 1 then -- Omit the hor-first
    return {ver_first}
  else
    return {ver_first, hor_first}
  end
end

print("Viable moves from {4, 3} to {2, 1} on keypad:")
ex_moves = to_pos_keypad({4,3}, {2,1})
for _,move in ipairs(ex_moves) do
  print(table.concat(move))
end

print("Viable moves from {2, 1} to {2, 3} on keypad:")
ex_moves = to_pos_keypad({2,1}, {2,3})
for _,move in ipairs(ex_moves) do
  print(table.concat(move))
end

-- Possible moves from one position to the target on the dirpad.
-- TODO: do not return two moves where there is only one straight line
function to_pos_dirpad (cur_pos, tar_pos)
  local delta = utils.sub_vec(tar_pos, cur_pos)
  local ver_first, hor_first = delta_to_moves(delta)
  if delta[1] == 0 or delta[2] == 0 then
    return {ver_first}
  end
  -- Omit the hor-first or ver-first depending on the positions.
  if cur_pos[1] == 2 and cur_pos[2] == 1 then -- Omit ver_first
    return {hor_first}
  elseif tar_pos[1] == 2 and tar_pos[2] == 1 then -- Omit hor_first
    return {ver_first}
  else
    return {ver_first, hor_first}
  end
end

print("Viable moves from {2, 1} to {1, 3} on dirpad:")
ex_moves = to_pos_dirpad({2,1}, {1,3})
for _, move in ipairs(ex_moves) do
  print(table.concat(move))
end

print("Viable moves from {2, 2} to {2, 3} on dirpad:")
ex_moves = to_pos_dirpad({2,2}, {2,3})
for _, move in ipairs(ex_moves) do
  print(table.concat(move))
end

-- Ideas:
-- * Maybe we have to prune sequences which are not the shortest at each stage.
-- or the ones which are not the straightest.
-- * At the end of typing every key on the keypad, every robot is
--   on A except the one at the keypad. This means we can proceed
--   by finding the shortest sequence one number at a time (still saving
--   the state of the robot at the keypad in between).
-- * Can we memoize the shortest sequences depending on the states of
--   the robots in some way?
-- * We can maybe select the shortest path by looking at the current
--   state of robots, and choose the keys on which they already are first.

-- Possible moves to reach a given key on the keypad from the current
-- position.
function moves_to_reach_key_keypad (cur_pos, key)
  local key_pos = pos_in_keypad(key)
  return to_pos_keypad(cur_pos, key_pos)
end

-- Possible moves to reach a given key on the dirpad from the current
-- position.
function moves_to_reach_key_dirpad (cur_pos, key)
  local key_pos = pos_in_dirpad(key)
  return to_pos_dirpad(cur_pos, key_pos)
end

print("Reach 8 from 4,3 on the keypad:")
ex_moves = moves_to_reach_key_keypad({4,3}, '8')
for _, move in ipairs(ex_moves) do
  print(table.concat(move))
end

print("Reach > from 1,2 on the dirpad:")
ex_moves = moves_to_reach_key_dirpad({1,2}, '>')
for _, move in ipairs(ex_moves) do
  print(table.concat(move))
end

-- Begin by finding the shortest sequence for typing 0 when starting from A
function shortest_seq (key, start_pos)
  local keypad_pos = utils.copy_table(start_pos)
  local keypad_moves = moves_to_reach_key_keypad(keypad_pos, key)
  keypad_pos = pos_in_keypad(key)
  local top_level = {}
  for _, move1 in ipairs(keypad_moves) do
    local robot1_pos = {1,3}
    local per_dirpad1_key = {}
    for _, dirpad1_key in ipairs(move1) do
      local robot1_moves = moves_to_reach_key_dirpad(robot1_pos, dirpad1_key)
      robot1_pos = pos_in_dirpad(dirpad1_key)
      local per_move2 = {}
      for _, move2 in ipairs(robot1_moves) do
        local robot2_pos = {1,3}
        local final_seqs = {}
        for _, dirpad2_key in ipairs(move2) do
          local robot2_moves = moves_to_reach_key_dirpad(robot2_pos, dirpad2_key)
          robot2_pos = pos_in_dirpad(dirpad2_key)
          local competing_final_seq = {}
          for _, seq in ipairs(robot2_moves) do
            table.insert(competing_final_seq, utils.copy_table(seq))
          end
          table.insert(final_seqs, utils.copy_table(competing_final_seq))
        end
        table.insert(per_move2, utils.copy_table(final_seqs))
      end
      table.insert(per_dirpad1_key, utils.copy_table(per_move2))
    end
    table.insert(top_level, utils.copy_table(per_dirpad1_key))
  end
  return top_level
end

-- TODO: concatenate the final sequence at each stage, taking the shortest
--       possibility at each level of concatenation.

top_seqs = shortest_seq('A', pos_in_keypad('9'))
-- print("Final sequences:")
-- for _, seq1 in ipairs(top_seqs) do
--   print("per_move1")
--   for _, seq2 in ipairs(seq1) do
--     print("  per_key1")
--     for _, seq3 in ipairs(seq2) do
--       print("    per_move2")
--       for _, seq4 in ipairs(seq3) do
--         print("      per_key2")
--         for _, seq5 in ipairs(seq4) do
--           print("        equiv final:")
--           print("        ", table.concat(seq5))
--         end
--       end
--     end
--   end
-- end

-- Concatenate all possible combinations of sequences given two sets
function concat_variations (set1, set2)
  local seqs = {}
  if #set1 == 0 then
    return set2
  end
  for _, seq1 in ipairs(set1) do
    for _, seq2 in ipairs(set2) do
      table.insert(seqs, utils.concat(seq1, seq2))
    end
  end
  return seqs
end

-- Concatenate all possible combinations of sequences given a list of sets
function concat_variations_list (set_list)
  local concat_set = {}
  for _, set in ipairs(set_list) do
    concat_set = concat_variations(concat_set, set)
  end
  return concat_set
end

print("concat_variations: ")
ex_concats = concat_variations({{1,2,3}, {3,2}}, {{6}, {5}})
for _, concat in ipairs(ex_concats) do
  print(table.concat(concat))
end

print("concat_variations_list: ")
ex_concats = concat_variations_list({{{1,2,3}}, {{4,4}, {4,5}}, {{8, 8}, {8,9}}})
for _, concat in ipairs(ex_concats) do
  print(table.concat(concat))
end

-- Given the tree of sequences, find all possible final sequences combinations
function find_final_sequences (top_seqs)
  local seqs = {}
  local move1_variations = {}
  for _, per_move1 in ipairs(top_seqs) do
    local key1_variations = {}
    for _, per_key_1 in ipairs(per_move1) do
      local move2_variations = {}
      for _, per_move2 in ipairs(per_key_1) do
        move2_variations = concat_variations_list(per_move2)
        -- print("#move2_variations: ", #move2_variations)
        -- for _, seq in ipairs(move2_variations) do
        --   print(table.concat(seq))
        -- end
      end
      key1_variations = utils.concat(key1_variations, {move2_variations})
    end
    -- print("#key1_variations: ", #key1_variations)
    -- for _, var in ipairs(key1_variations) do
    --   print("var: ")
    --   for _, seq in ipairs(var) do
    --     print(table.concat(seq))
    --   end
    -- end
    move1_variations = concat_variations_list(key1_variations)
    -- print("#move1_variations: ", #move1_variations)
    seqs = utils.concat(seqs, move1_variations)
  end
  return seqs
end

final_seqs = find_final_sequences(top_seqs)
print("Final sequences:")
for _, seq in ipairs(final_seqs) do
  print(table.concat(seq))
end

-- Final sequences for example:
-- 0: <vA<AA>>^AvAA<^A>A
-- 2: <v<A>>^AvA^A
-- 9:

-- Find the shortest sequence in a set of sequences
function shortest_len (seqs)
  local len = 1e9
  for _, seq in ipairs(seqs) do
    len = math.min(len, #seq)
  end
  return len
end

-- Running the full code, get the shortest_len for each digit
function run_code (keys)
  local total_len = 0
  local last_key = 'A'
  for _, key in ipairs(keys) do
    local top_seqs = shortest_seq(key, pos_in_keypad(last_key))
    local final_sequences = find_final_sequences(top_seqs)
    local len = shortest_len(final_sequences)
    print("Shortest sequence for key ", key, len)
    total_len = total_len + len
    last_key = key
  end
  return total_len
end

for _, code in ipairs(ex_codes) do
  print("code: ", table.concat(code))
  local total_len = run_code(code)
  print("Total length: ", total_len)
end

-- Extract the numeric part of a code
function code_numeric (code)
  code_str = table.concat(code)
  code_int = code_str:gmatch"%d+"
  return tonumber(code_int())
end

print("Numeric part of 029A: ", code_numeric(ex_codes[1]))
print("Numeric part of 980A: ", code_numeric(ex_codes[2]))
print("Numeric part of 179A: ", code_numeric(ex_codes[3]))
print("Numeric part of 456A: ", code_numeric(ex_codes[4]))

-- Compute a code complexity code according to the instructions
function code_complexity (code)
  local code_num = code_numeric(code)
  local code_len = run_code(code)
  return code_num * code_len
end

-- Get the accumulated complexity of all codes
function accumulate_complexity (codes)
  local count = 0
  for _, code in ipairs(codes) do
    count = count + code_complexity(code)
  end
  return count
end

print("Example result: ", accumulate_complexity(ex_codes))
print("Input result: ", accumulate_complexity(input_codes))

-- # Part 2
