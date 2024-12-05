-- Day 05

-- # Parsing the input
-- Get the file as a text string.
function file_to_str (filepath)
  local file = io.open(filepath)
  local input_str = file:read("*a")
  file:close()
  return input_str
end

-- Iterator on lines
function lines (str)
  return string.gmatch(str, "[^\n]+")
end

example_str =
  "47|53\n"
  .. "97|13\n"
  .. "97|61\n"
  .. "97|47\n"
  .. "75|29\n"
  .. "61|13\n"
  .. "75|53\n"
  .. "29|13\n"
  .. "97|29\n"
  .. "53|29\n"
  .. "61|53\n"
  .. "97|53\n"
  .. "61|29\n"
  .. "47|13\n"
  .. "75|47\n"
  .. "97|75\n"
  .. "47|61\n"
  .. "75|61\n"
  .. "47|29\n"
  .. "75|13\n"
  .. "53|13\n"
  .. "\n"
  .. "75,47,61,53,29\n"
  .. "97,61,53,29,13\n"
  .. "75,29,13\n"
  .. "75,97,47,61,53\n"
  .. "61,13,29\n"
  .. "97,13,75,29,47\n"

print(example_str)
input_str = file_to_str("input.txt")

-- Break the input string into the ruleset block and the updates block.
function break_input_blocks (str)
  local split_pos = string.find(str, "\n\n")
  local rule_block = string.sub(str, 1, split_pos - 1)
  local updates_block = string.sub(str, split_pos + 1, #str)
  return rule_block, updates_block
end

example_rules_str, example_updates_str = break_input_blocks(example_str)
input_rules_str, input_updates_str = break_input_blocks(input_str)

-- Parse the rule block into a table of pairs.
function parse_rules_to_table (rules_str)
  local rules_table = {}
  for line in lines(rules_str) do
    local rule_pair = {}
    for num in string.gmatch(line, "[^|]+") do
      table.insert(rule_pair, tonumber(num))
    end
    table.insert(rules_table, rule_pair)
  end
  return rules_table
end

example_rules_table = parse_rules_to_table(example_rules_str)
for _, pair in ipairs(example_rules_table) do
  print(table.concat(pair, " "))
end
input_rules_table = parse_rules_to_table(input_rules_str)

-- Parse the update sequences
function parse_updates_to_table (updates_str)
  local updates_table = {}
  for line in lines(updates_str) do
    local update = {}
    for num in string.gmatch(line, "[^,]+") do
      table.insert(update, tonumber(num))
    end
    table.insert(updates_table, update)
  end
  return updates_table
end

example_updates_table = parse_updates_to_table(example_updates_str)
for _, update in ipairs(example_updates_table) do
  print(table.concat(update, ' '))
end
input_updates_table = parse_updates_to_table(input_updates_str)

-- # Part 1
-- We parse the rules into an associative array keyed by the first number,
-- and containing another associative array with the second number as keys.
-- This allows to search through the rules efficiently.
-- Then we proceed through each update sequence in reverse, checking every
-- previous number to see if it was actually supposed to be after the
-- one we are looking at.

-- Parse the rules table into a queryable rules array.
function parse_rules_into_assoc (rules_table)
  local rules_assoc = {}
  for _, rule in ipairs(rules_table) do
    if not rules_assoc[rule[1]] then
      rules_assoc[rule[1]] = {}
    end
    rules_assoc[rule[1]][rule[2]] = true
  end
  return rules_assoc
end

example_rules_assoc = parse_rules_into_assoc(example_rules_table)
for first_page, second_pages in pairs(example_rules_assoc) do
  print(first_page, ": ")
  for second_page, _ in pairs(second_pages) do
    print(second_page)
  end
end
input_rules_assoc = parse_rules_into_assoc(input_rules_table)

-- Determine if a given update is compliant with the rules
-- We go in reverse along the numbers, getting the corresponding
-- rule, and checking every previous number to see if it was
-- actually supposed to be after.
function update_is_compliant (update, rules_assoc)
  local n = #update
  for i = 1, n do
    local cur_page = update[n + 1 -i]
    local cur_rule = rules_assoc[cur_page]
    if cur_rule then -- If there is a rule at all for the current page.
      -- Check every previous number in the update.
      for j = 1, n + 1 - i - 1 do
        -- If we find that a number was supposed to be after
        -- the cur_page, then the update is not compliant.
        local check_num = update[j]
        if cur_rule[check_num] then
          return false
        end
      end
    end
  end
  return true
end

for i_example = 1, 6 do
print(update_is_compliant(example_updates_table[i_example], example_rules_assoc))
end

-- Take the middle number of an odd-length sequence
function take_middle (seq)
  local n = #seq
  return seq[(n+1 + 0.5)//2]
end

print(take_middle({1,2,3,4,5}))

-- Check every update and accumulate the middle page number
function accumulate_valid_updates (updates_table, rules_assoc)
  local count = 0
  for _, update in ipairs(updates_table) do
    if update_is_compliant(update, rules_assoc) then
      local middle = take_middle(update)
      count = count + middle
    end
  end
  return count
end

example_part1_result = accumulate_valid_updates(example_updates_table,
                                                example_rules_assoc)
print("Part 1 example result: ", example_part1_result)
part1_result = accumulate_valid_updates(input_updates_table,
                                        input_rules_assoc)
print("Part 1 result: ", part1_result)

-- # Part 2
-- We can iterate from the end of the updates as before,
-- except this time we swap the numbers when a conflict is seen.
-- We repeat the full loop of swapping as long as the sequence is incorrect.

-- Return the position of the first offending number, if any,
-- from 1 up to icheck-1
function first_offending_position (update, icheck, rule)
  for i = 1, icheck - 1 do
    local num = update[i]
    if rule[num] then
      return i
    end
  end
  return nil
end

function copy_table (tab)
  local ctab = {}
  for k, v in pairs(tab) do
    ctab[k] = v
  end
  return ctab
end

-- Reorder an update according to the rules
function reorder_update (old_update, rules_assoc)
  local update = copy_table(old_update)
  local n = #update
  local update_compliant = false
  while not update_compliant do
    update_compliant = true
    for i = 1, n do
      local icheck = n + 1 - i
      local cur_page = update[icheck]
      local cur_rule = rules_assoc[cur_page]
      if cur_rule then
        local offending_pos = first_offending_position(update, icheck, cur_rule)
        if offending_pos then -- Swap
          local temp = update[icheck]
          update[icheck] = update[offending_pos]
          update[offending_pos] = temp
          update_compliant = false
        end
      end
    end
  end
  return update
end

example_reordered = reorder_update(example_updates_table[6], example_rules_assoc)
print("Reordered example: ", table.concat(example_reordered, ' '))

-- Go through all updates, select the incorrect ones, reorder them,
-- take the middle and accumulate.
function accumulate_reordered_updates (updates, rules_assoc)
  local count = 0
  for _, update in ipairs(updates) do
    if not update_is_compliant(update, rules_assoc) then
      local reordered_update = reorder_update(update, rules_assoc)
      local middle = take_middle(reordered_update)
      count = count + middle
    end
  end
  return count
end

example_part2_result = accumulate_reordered_updates(example_updates_table,
                                                    example_rules_assoc)
print("Part 2 example result: ", example_part2_result)
part2_result = accumulate_reordered_updates(input_updates_table,
                                            input_rules_assoc)
print("Part 2 result: ", part2_result)
