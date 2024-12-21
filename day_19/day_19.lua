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

-- # Part 2
-- We initially tried to do it but the input wouldn't run in reasonable time.
-- Maybe we need to pre-count the number of ways a towel can be made with
-- other towels first.


-- Return the indices of towel which build the given pattern.
function iter_searchall (subpat, towels, itowels, success_sequences)
  for itowel, towel_len in iter_matching_towels(towels, subpat) do
    local new_itowels = utils.copy_table(itowels)
    table.insert(new_itowels, itowel)
    -- print("new_itowels: ", table.concat(new_itowels, ','))
    if 1 + towel_len > string.len(subpat) then
      table.insert(success_sequences, new_itowels)
      return
    else -- Continue the search
      local new_subpat = string.sub(subpat, 1 + towel_len)
      iter_searchall(new_subpat, towels, new_itowels, success_sequences)
    end
  end
end

-- Find all towel sequences which can build a pattern
function search_alltowels (pattern, towels)
  local success_sequences = {}
  local subtowels = sub_towels(towels, pattern)
  iter_searchall(pattern, subtowels, {}, success_sequences)
  return success_sequences
end

ex_success_towels = search_alltowels(ex_patterns[1], ex_towels)
print("Matching towel sequences for first pattern: ")
print("Found ", #ex_success_towels, " sequences")
for _, seq in ipairs(ex_success_towels) do
  print(table.concat(seq, ', '))
end
ex_success_towels = search_alltowels(ex_patterns[3], ex_towels)
print("Matching towel sequences for third pattern: ")
print("Found ", #ex_success_towels, " sequences")
for _, seq in ipairs(ex_success_towels) do
  print(table.concat(seq, ', '))
end

-- Trying to see what is happening in the problematic input
-- print(" # Debugging problematic input pattern: ")
-- input_success_towels = search_alltowels(input_patterns[2], input_towels)

-- We can try matching with the towel which can be made from the most other
-- towels first (this should also be the longest match I think),
-- and omit the matches with those other towels,
-- simply note the number of possibilities to make this towel and multiply with
-- the rest of the search.
-- I don't think it is sufficient to match the longest towel only.

print("Unique elements in: ", table.concat({1,2,3,4,2,1,1}, ','),
      table.concat({1,6,6,6}, ','))
print(table.concat(utils.unique_in_sequences({{1,2,3,4,2,1,1}, {1,6,6,6}}), ','))


-- Preprocess a towel to:
-- {string, number of ways it can be obtained from the other towels,
--  towel indices involved in obtaining this towel}
function preprocess_towel (towels, itowel)
  local towel = towels[itowel]
  local possible_sequences = search_alltowels(towel, towels)
  local nseqs = #possible_sequences
  local unique_itowels = utils.unique_in_sequences(possible_sequences)
  return {towel, nseqs, unique_itowels}
end

-- Preprocess all towels.
function preprocess_towels (towels)
  local preprocessed_towels = {}
  for i = 1, #towels do
    local preprocessed_towel = preprocess_towel(towels, i)
    table.insert(preprocessed_towels, preprocessed_towel)
  end
  return preprocessed_towels
end

ex_pre_towels = preprocess_towels(ex_towels)
print("Pre-processed example towels: ")
for _, ptowel in ipairs(ex_pre_towels) do
  print(ptowel[1], ptowel[2], table.concat(ptowel[3], ','))
end

input_pre_towels = preprocess_towels(input_towels)
print("Pre-processed input towels: ")
for _, ptowel in ipairs(input_pre_towels) do
  print(ptowel[1], ptowel[2], table.concat(ptowel[3], ','))
end


-- grgbrwt
-- grgbrw
--      wt
--      w
-- grgbr
-- gr
--       t
-- grgbrw + t
-- grgbr + wt
-- grgbr + w + t
-- If I match grgbrw I cannot match grgbr + wt

-- This could be decomposed as,
-- Number of ways to make 'g' * number of ways to make 'rgbrwt'
-- + nways to make 'gr' * number of ways to make 'gbrwt'
-- + ...

-- and then each step can also be recursed in.
-- We can further speed-up by memoizing the number of ways already found
-- for bigger substrings. It seems the runtime will still be factorial though...
-- We can put the towel strings in a hashmap for quick matching.

-- Maybe we can find the ways to create the pattern with
-- towels which are not composite, and then count how many other
-- towels may be built by concatenating these towels?

-- Return the non-composite towels from the preprocessed towels.
function find_non_composites (pre_towels)
  local elem_towels  = {}
  for _, ptowel in ipairs(pre_towels) do
    if ptowel[2] == 1 then
      table.insert(elem_towels, ptowel[1])
    end
  end
  return elem_towels
end

input_elem_towels = find_non_composites(input_pre_towels)
print("Input non-composite towels: ")
for _, towel in ipairs(input_elem_towels) do
  print(towel)
end

-- Trying to see what is happening in the problematic input with non-composite
-- towels.
-- print(" # Debugging problematic input pattern: ")
-- for _, pattern in ipairs(input_patterns) do
--   input_success_towels = search_alltowels(pattern, input_elem_towels)
--   print("Found elementary sequences: ", #input_success_towels)
-- end
-- Still very slow, this is not the answer.

-- Put the pre-processed towels into a hasmap of key: towel, value: number
-- of ways they can be obtained from other towels.
function to_towels_hashmap (pre_towels)
  local hashmap = {}
  for _, pre_towel in ipairs(pre_towels) do
    hashmap[pre_towel[1]] = pre_towel[2]
  end
  return hashmap
end

ex_hash_towels = to_towels_hashmap(ex_pre_towels)
print("Example towels hashes: ")
for k, v in pairs(ex_hash_towels) do
  print(k, v)
end
input_hash_towels = to_towels_hashmap(input_pre_towels)

-- Recurse to find the number of ways we can build a given pattern
function nways (pattern, towels_hashcount)
  if towels_hashcount[pattern] then
    return towels_hashcount[pattern]
  else
    local n = 0
    local pattern_len = string.len(pattern)
    for i = 1, pattern_len - 1 do
      -- print("Sub1: ", string.sub(pattern, 1, i))
      -- print("Sub2: ", string.sub(pattern, i+1, pattern_len))
      local res_i = nways(string.sub(pattern, 1, i), towels_hashcount)
        * nways(string.sub(pattern, i+1, pattern_len), towels_hashcount)
      -- print("Sub1: ", string.sub(pattern, 1, i))
      -- print("Sub2: ", string.sub(pattern, i+1, pattern_len))
      -- print("res_i: ", res_i)
      -- TODO: memoize the result in the hashmap.
      n = n + res_i
    end
    return n
  end
end

ex_nways = nways("rrwr", ex_hash_towels)
print("Example nways first pattern: ", ex_nways) -- this is wrong
--input_nways = nways(input_patterns[2], input_hash_towels)
-- still too slow so that's not it.


-- We could try to recurse with:
-- Find all towels in the hashmap which match the beginning,
-- multiply their count by the nways of the remainder of the pattern
-- and sum. Memoize the result.
-- I think this is equivalent to our first approach though.

-- Return whether a given towel matches the beginning of the
-- pattern, and the rest of the pattern if it does.
function does_towel_match_begin_rest (towel, pattern)
  local pattern_len = string.len(pattern)
  local towel_len = string.len(towel)
  if pattern_len < towel_len then
    return false, nil
  end
  local sub_pat = string.sub(pattern, 1, towel_len)
  local rest_pat = string.sub(pattern, towel_len + 1, pattern_len)
  return sub_pat == towel, rest_pat
end

ex_towel_rest, ex_towel_restpat = does_towel_match_begin_rest("brr", "brrr")
print("Example towel and rest: ", ex_towel_restpat)

-- Iterator to remaining patterns when a towel match is found for the
-- beginning of the pattern
function iter_matching_towels_rest (towels, pattern)
  local itowel = 0
  local ntowels = #towels
  return function()
    while itowel < ntowels do
      itowel = itowel + 1
      local towel = towels[itowel]
      local match, rest_pattern = does_towel_match_begin_rest(towel, pattern)
      if match then
        return rest_pattern
      end
    end
  end
end

-- Count the number of possible ways to build the pattern from towels.
function count_nways (towels, towel_hashcounts, pattern)
  local count = 0
  if not pattern then
    return 1
  end
  if towel_hashcounts[pattern] then
    return towel_hashcounts[pattern]
  end
  for rest_pattern in iter_matching_towels_rest(towels, pattern) do
    count = count + count_nways(towels, towel_hashcounts, rest_pattern)
  end
  towel_hashcounts[pattern] = count
  return count
end

for i_ex = 1, 8 do
  ex_count_nways = count_nways(ex_towels, utils.copy_table(ex_hash_towels),
                               ex_patterns[i_ex])
  print("Example ", i_ex, ex_patterns[i_ex], " count nways: ", ex_count_nways)
end

input_count_nways = count_nways(input_towels, utils.copy_table(input_hash_towels),
                                input_patterns[2])
print("Input compare with nways")
print("Input single pattern: ", input_count_nways)

-- Add up all possible ways of making patterns from towels
function add_nways (towels, towel_hashcounts, patterns)
  local count = 0
  for _, pattern in ipairs(patterns) do
    local single_count = count_nways(towels, utils.copy_table(towel_hashcounts),
                                     pattern)
    count = count + single_count
    print(count)
  end
  return count
end

ex_part2_result = add_nways(ex_towels, ex_hash_towels, ex_patterns)
print("Example part 2 result: ", ex_part2_result)
--input_part2_result = add_nways(input_towels, input_hash_towels, input_patterns)
--print("Part 2 result: ", input_part2_result)

-- Tried 530276499894300, too low
--       678536865274732

-- grgbrwt
-- grgbrw
--      wt
--      w
-- grgbr
-- gr
--       t
-- grgbrw + t
-- grgbr + wt
-- grgbr + w + t
-- Answer: 3 ways

-- decompose count_nways:
-- matching:
-- * grgbrw, t
--   * count = 1
-- * grgbr, wt
--   * count(wt) = 2
-- * gr, gbrwt

-- Count the nways to build a pattern in a naive way, to
-- build the hashmap of towels.
function count_nways_naive (towels, pattern)
  local count = 0
  if not pattern then
    return 1
  end
  for _, towel in ipairs(towels) do
    if towel == pattern then
      count = 1
    end
  end
  for rest_pattern in iter_matching_towels_rest(towels, pattern) do
    count = count + count_nways_naive(towels, rest_pattern)
  end
  return count
end

function compute_towels_hash (towels)
  local hashes = {}
  for _, towel in ipairs(towels) do
    hashes[towel] = count_nways_naive(towels, towel)
  end
  return hashes
end

ex_man_towels = {"grgbrw", "wt", "w", "grgbr", "gr", "t"}

ex_man_towels_wt = count_nways_naive(ex_man_towels, "wt")
print("Manual example number of towels for wt: ", ex_man_towels_wt)

ex_man_hashes = compute_towels_hash(ex_man_towels)
print("Manual example hashmap:")
for k, v in pairs(ex_man_hashes) do
  print(k, v)
end
ex_man_pattern = "grgbrwt"
ex_man_res = count_nways(ex_man_towels, utils.copy_table(ex_man_hashes),
                         ex_man_pattern)
print("Manual example result: ", ex_man_res)

ex2_towels = ex_towels
ex2_hashes = compute_towels_hash(ex2_towels)
print("Example hashmap:")
for k, v in pairs(ex2_hashes) do
  print(k, v)
end
print("Example number of ways: ")
for _, pattern in ipairs(ex_patterns) do
  print(pattern, count_nways(ex2_towels, utils.copy_table(ex2_hashes), pattern))
end
print("Example result: ", add_nways(ex2_towels, ex2_hashes, ex_patterns))

input2_towels = input_towels
input2_hashes = compute_towels_hash(input2_towels)
input2_res = add_nways(input2_towels, input2_hashes, input_patterns)
