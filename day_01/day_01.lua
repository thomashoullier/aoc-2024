-- Day 01
-- # Part 1.
-- 1. We parse the two lists.
-- 2. We sort each list independently.
-- 3. We iterate over the lists in increasing order, accumulating the difference
--    between the number pairs along the way. The result is the accumulated
--    difference.

part1_ex1 = "3   4\n"
         .. "4   3\n"
         .. "2   5\n"
         .. "1   3\n"
         .. "3   9\n"
         .. "3   3\n"

print("Part 1: example input:\n" .. part1_ex1)

-- Parse the input text into two lists of numbers.
function parse_input (str)
  local list1 = {}
  local list2 = {}
  -- First parse all numbers as strings
  local list_numstr = {}
  for s in string.gmatch(str, "[^%s]+") do
    table.insert(list_numstr, s)
  end
  -- Then convert number strings to integers and dispatch to the two lists.
  for i = 1, #list_numstr, 2 do
    table.insert(list1, tonumber(list_numstr[i]))
  end
  for i = 2, #list_numstr, 2 do
    table.insert(list2, tonumber(list_numstr[i]))
  end
  return list1, list2
end

-- Sort the lists, compute the distance between them
function distance_lists (list1, list2)
  -- First sort the lists independently.
  slist1 = list1
  table.sort(slist1)
  slist2 = list2
  table.sort(slist2)
  -- Iterate over both and accumulate distance
  assert(#slist1 == #slist2, "Lists have unequal lenghts")
  local distance = 0
  for i = 1, #slist1 do
    distance = distance + math.abs(slist1[i] - slist2[i])
  end
  return distance
end

-- Example
ex_list1, ex_list2 = parse_input(part1_ex1)
print("part1_ex1 list1: ", table.concat(ex_list1, '\n'))
print("part1_ex1 list2: ", table.concat(ex_list2, '\n'))
ex_total_distance = distance_lists(ex_list1, ex_list2)
print("part1_ex1 distance: ", ex_total_distance)
-- Actual data
local file = io.open("input.txt")
str = file:read("*a")
list1, list2 = parse_input(str)
total_distance = distance_lists(list1, list2)
print("Part 1 total distance: ", total_distance)
file:close()

-- # Part 2.
-- 1. We go over the right list, counting the number of occurences for each
-- number.
-- 2. We go over the left list and get its number of occurences in the right
--    list and accumulate num * occurences.

-- Establish a table of number of occurences per number.
function occurence_counts (list)
  local occurences = {}
  for i = 1, #list do
    local num = list[i]
    if (occurences[num] == nil) then
      occurences[num] = 1
    else
      occurences[num] = occurences[num] + 1
    end
  end
  return occurences
end

ex_occurences = occurence_counts(ex_list2)
print("ex_occurences: ")
for i,v in pairs(ex_occurences) do
  print(i, v)
end

-- Accumulate the similarity score over the left table given the occurence counts
function similarity_score (list, occurences)
  local score = 0
  for i,v in ipairs(list) do
    local count = occurences[v]
    if (count == nil) then
      count = 0
    end
    score = score + count * v
  end
  return score
end

ex_similarity = similarity_score(ex_list1, ex_occurences)
print("ex_similarity: ", ex_similarity)

-- Actual data
occurences = occurence_counts(list2)
similarity = similarity_score(list1, occurences)
print("Part 2 similarity score: ", similarity)
