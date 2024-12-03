-- AOC 2024 Day 02.

ex_part1_input =
   "7 6 4 2 1\n"
.. "1 2 7 8 9\n"
.. "9 7 6 2 1\n"
.. "1 3 2 4 5\n"
.. "8 6 4 4 1\n"
.. "1 3 6 7 9\n"

-- Parse the input string for the problem into an internal representation
function parse_input (str)
  local input_table = {}
  for line in string.gmatch(str, "[^\n]+") do
    local line_table = {}
    for numstr in string.gmatch(line, "[^%s]+") do
      table.insert(line_table, tonumber(numstr))
    end
    table.insert(input_table, line_table)
  end
  return input_table
end

ex_part1_parsed = parse_input(ex_part1_input)
for iline = 1, #ex_part1_parsed do
  print(table.concat(ex_part1_parsed[iline], ' '))
end

-- Check whether a given report is increasing?
function report_is_increasing (report)
  local last = report[1]
  for i = 2, #report do
    if last > report[i] then
      return false
    end
    last = report[i]
  end
  return true
end

function report_is_decreasing (report)
  local last = report[1]
  for i = 2, #report do
    if last < report[i] then
      return false
    end
    last = report[i]
  end
  return true
end

-- Do adjacent elements differ by at least one and at most three?
function safe_difference (report)
  local last = report[1]
  for i = 2, #report do
    local diff = math.abs(report[i] - last)
    if diff < 1 then
      return false
    end
    if diff > 3 then
      return false
    end
    last = report[i]
  end
  return true
end

-- Check whether a given single report is safe (true) or not (false).
function report_is_safe (report)
  local monotone_b = (report_is_increasing(report) or
                      report_is_decreasing(report))
  local safe_difference_b = safe_difference(report)
  return (monotone_b and safe_difference_b)
end

print(report_is_safe(ex_part1_parsed[1]))

function count_safe_reports (reports)
  local count = 0
  for i, report in ipairs(reports) do
    if (report_is_safe(report))
    then
      count = count + 1
    end
  end
  return count
end

print("Part 1 example, number of safe reports: ",
      count_safe_reports(ex_part1_parsed))

-- Part 1 - Actual data
file = io.open("input.txt")
str = file:read("*a")
reports = parse_input(str)
n_safe_reports = count_safe_reports(reports)
print("Part 1, number of safe reports: ", n_safe_reports)

-- Part 2
-- The input is not that long. We can use a naive method.

-- Output every possible report with one element removed.
function one_removed_reports (report)
  local reports = {}
  for i_removed = 1, #report do
    local cur_report = {}
    for i_elem = 1, #report do
      if i_elem ~= i_removed then
        table.insert(cur_report, report[i_elem])
      end
    end
    table.insert(reports, cur_report)
  end
  return reports
end

ex_one_removed = one_removed_reports(ex_part1_parsed[1])
for i, v in ipairs(ex_one_removed) do
  print(table.concat(v, ' '))
end

-- Count the number of dampened safe reports
function count_dampened_safe_reports(reports)
  local count = 0
  for i, report in ipairs(reports) do
    if report_is_safe(report) then
      count = count + 1
    else
      local one_removeds = one_removed_reports(report)
      local dampened_safe_found_b = false
      for j, dampened_report in ipairs(one_removeds) do
        if report_is_safe(dampened_report) then
          dampened_safe_found_b = true
        end
      end
      if dampened_safe_found_b then
        count = count + 1
      end
    end
  end
  return count
end

-- Part 2 example:
print("Part 2 example result: ", count_dampened_safe_reports(ex_part1_parsed))

-- Part 2 solution:
print("Part 2 solution: ", count_dampened_safe_reports(reports))
