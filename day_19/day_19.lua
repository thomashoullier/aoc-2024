-- Day 19
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

input_str = utils.file_to_string("input.txt")
ex_str = "r, wr, b, g, bwu, rb, gb, br\n"
      .. "\n"
      .. "brwrr\n"
      .. "bggr\n"
      .. "gbbr\n"
      .. "rrbgbr\n"
      .. "ubwu\n"
      .. "bwurrg\n"
      .. "brgr\n"
      .. "bbrgwb\n"

-- # Parsing

-- Parse the towel block
function parse_towels (str)
  local towels = {}
  for towel in utils.iter_on_separator(str, ', ') do
    table.insert(towels, towel)
  end
  return towels
end

-- Parse the patterns block
function parse_patterns (str)
  local patterns = {}
  for line in utils.lines(str) do
    table.insert(patterns, line)
  end
  return patterns
end

-- Parse the input
function parse_input (str)
  local blocks = utils.iter_blocks(str)
  local towels_block = blocks()
  local patterns_block = blocks()
  local towels = parse_towels(towels_block)
  local patterns = parse_patterns(patterns_block)
  return towels, patterns
end

ex_towels, ex_patterns = parse_input(ex_str)
print("Example towels: ", table.concat(ex_towels, ', '),
      "\nExample patterns:\n", table.concat(ex_patterns, '\n'))
input_towels, input_patterns = parse_input(input_str)

-- # Part 1
-- A sensible first step is to filter out all the towels which are not
-- even a substring in the target pattern.

-- Return the towels which are a substring of the target pattern
function sub_towels (towels, pattern)
  local subs = {}
  for _, towel in ipairs(towels) do
    if string.find(pattern, towel) then
      table.insert(subs, towel)
    end
  end
  return subs
end

-- Get the set of sub_towels for each pattern
function all_sub_towels (towels, patterns)
  local sub_set = {}
  for _, pattern in ipairs(patterns) do
    table.insert(sub_set, sub_towels(towels, pattern))
  end
  return sub_set
end

ex_subtowels = all_sub_towels(ex_towels, ex_patterns)
print("Example subtowels: ")
for _, subset in ipairs(ex_subtowels) do
  print(table.concat(subset, ', '))
end

input_subtowels = all_sub_towels(input_towels, input_patterns)
-- print("Input subtowels: ")
-- for _, subset in ipairs(input_subtowels) do
--   print(table.concat(subset, ', '))
-- end

-- We assume it is always better to use the smallest possible towels
-- to check whether a pattern is possible or not. So we can filter out the
-- big towels which can be recreated entirely with smaller towels.
-- (this is close to solving the actual problem though)

-- We can go position by position in the pattern, looking for all
-- possible matching towels at the beginning of the string, advance by the size
-- of the towel and recurse.

-- Check whether a towel matches the beginning of the provided pattern
function does_towel_match_begin (towel, pattern)
  local pattern_len = string.len(pattern)
  local towel_len = string.len(towel)
  if pattern_len < towel_len then return false end
  local sub_pat = string.sub(pattern, 1, towel_len)
  return sub_pat == towel
end

ex_submatch = does_towel_match_begin("bwu", "bwurgg")
print("Ex submatch: ", ex_submatch)
ex_submatch = does_towel_match_begin("bu", "bwurgg")
print("Ex submatch: ", ex_submatch)

-- Iterator to all towel indices matching the beginning of the string.
function iter_matching_towels (towels, pattern)
  local itowel = 0
  local ntowels = #towels
  return function()
    while itowel < ntowels do
      itowel = itowel + 1
      local towel = towels[itowel]
      if does_towel_match_begin(towel, pattern) then
        return itowel, string.len(towel)
      end
    end
  end
end

print("Example matching towels: ")
for itowel, len in iter_matching_towels(ex_towels, "rbu") do
  print("itowel: ", itowel, " of length ", len)
end

-- Return the indices of towel which build the given pattern.
function iter_search (subpat, towels, itowels, success_sequences, match_found)
  if match_found[1] == true then
    return
  end
  for itowel, towel_len in iter_matching_towels(towels, subpat) do
    local new_itowels = utils.copy_table(itowels)
    table.insert(new_itowels, itowel)
    if 1 + towel_len > string.len(subpat) then
      match_found[1] = true
      table.insert(success_sequences, new_itowels)
      return
    else -- Continue the search
      local new_subpat = string.sub(subpat, 1 + towel_len)
      iter_search(new_subpat, towels, new_itowels, success_sequences, match_found)
    end
  end
end

-- Find all towel sequences which can build a pattern
function search_towels (pattern, towels)
  local success_sequences = {}
  iter_search(pattern, towels, {}, success_sequences, {false})
  return success_sequences
end

ex_success_towels = search_towels(ex_patterns[1], ex_towels)
print("Matching towel sequences for first pattern: ")
print("Found ", #ex_success_towels, " sequences")
for _, seq in ipairs(ex_success_towels) do
  print(table.concat(seq, ', '))
end

-- A given pattern is possible if we find sequences of towels
function pattern_is_possible (pattern, towels)
  local success_sequences = search_towels(pattern, towels)
  if #success_sequences > 0 then return true
  else return false
  end
end

print("Example possible patterns: ")
for _, pattern in ipairs(ex_patterns) do
  print("Pattern ", pattern, " is possible? ",
        pattern_is_possible(pattern, ex_towels))
end

function count_possible_patterns (patterns, towels)
  local count = 0
  for _, pattern in ipairs(patterns) do
    --print("Searching pattern: ", pattern)
    if pattern_is_possible(pattern, towels) then
      count = count + 1
    end
  end
  return count
end

ex_npossible = count_possible_patterns(ex_patterns, ex_towels)
print("Example possible patterns: ", ex_npossible)
input_npossible = count_possible_patterns(input_patterns, input_towels)
print("Part 1 result: ", input_npossible)
