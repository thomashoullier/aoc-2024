-- Day 04

-- # Parsing input
-- Note the input is a square, otherwise diagonal would not make sense.

-- Get the file as a text string.
function file_to_str (filepath)
  local file = io.open(filepath)
  local input_str = file:read("*a")
  file:close()
  return input_str
end

example_str = "MMMSXXMASM\n"
           .. "MSAMXMSMSA\n"
           .. "AMXSXMAAMM\n"
           .. "MSAMASMSMX\n"
           .. "XMASAMXAMM\n"
           .. "XXAMMXXAMA\n"
           .. "SMSMSASXSS\n"
           .. "SAXAMASAAA\n"
           .. "MAMMMXMMMM\n"
           .. "MXMXAXMASX\n"
input_str = file_to_str("input.txt")

-- Iterator on lines
function lines (str)
  return string.gmatch(str, "[^\n]+")
end

-- Iterator to the characters in a string.
function str_chars (str)
  return str:gmatch"."
end

-- Collect an iterator to a table
function collect_iter (iter)
  local tab = {}
  for v in iter do
    table.insert(tab, v)
  end
  return tab
end

-- Convert the input strings to a 2D matrix of characters.
function str_to_matrix (str)
  local matrix = {}
  for line in lines(str) do
    local char_line = collect_iter(str_chars(line))
    table.insert(matrix, char_line)
  end
  return matrix
end

example_matrix = str_to_matrix(example_str)
input_matrix = str_to_matrix(input_str)

-- # Part 1
-- We create iterators reading the character matrix in all 8 ways,
-- and returning a string.
-- We then look in all these strings for the pattern ~XMAS~

-- Convert a character table back to a string.
function char_table_to_str (char_table)
  return table.concat(char_table)
end

-- Iterator on left to right strings.
function left_right_strings (matrix)
  local i = 0
  local n = #matrix
  return function ()
    i = i + 1
    if i <= n then
      return char_table_to_str(matrix[i])
    end
  end
end

example_left_right_iter = left_right_strings(example_matrix)
print(example_left_right_iter())
print(example_left_right_iter())
print(example_left_right_iter())

-- Iterator on right to left strings.
function right_left_strings (matrix)
  local i = 0
  local n = #matrix
  return function ()
    i = i + 1
    if i <= n then
      return string.reverse(char_table_to_str(matrix[i]))
    end
  end
end

-- Get a a column of a 2D matrix
function get_column (matrix, j)
  local column = {}
  for _, row in ipairs(matrix) do
    table.insert(column, row[j])
  end
  return column
end

-- Iterator on top to bottom strings.
function top_bottom_strings (matrix)
  local j = 0
  local n = #(matrix[1])
  return function ()
    j = j + 1
    if j <= n then
      return char_table_to_str(get_column(matrix, j))
    end
  end
end

example_top_bottom_iter = top_bottom_strings(example_matrix)
print(example_top_bottom_iter())
print(example_top_bottom_iter())

-- Iterator on bottom to top strings.
function bottom_top_strings (matrix)
  local j = 0
  local n = #(matrix[1])
  return function ()
    j = j + 1
    if j <= n then
      return string.reverse(char_table_to_str(get_column(matrix, j)))
    end
  end
end

-- Get the k-th diagonal (top-left to bottom-right) of a 2D square matrix
-- Starting counting from the bottom of the matrix.
-- There are (n - 1) * 2 + 1 diagonals in total, of unequal length of course.
function get_diagonal (matrix, k)
  local diagonal = {}
  local n = #matrix
  local i_first = math.max(n - k + 1, 1)
  local j_first = math.max(-n + k + 1, 1)
  -- Now go down this diagonal
  for i = i_first, n do
    table.insert(diagonal, matrix[i][j_first + (i - i_first)])
  end
  return diagonal
end

print(char_table_to_str(get_diagonal(example_matrix, 2)))

-- Get the k-th antidiagonal (top-right to bottom-left) of a 2D square matrix
-- Starting counting from the top of the matrix.
function get_antidiagonal (matrix, k)
  local antidiagonal = {}
  local n = #matrix
  local i_first = math.max(-n + k + 1, 1)
  local j_first = math.min(k, n)
  -- Now go down this diagonal
  for i = i_first, n do
    table.insert(antidiagonal, matrix[i][j_first - (i - i_first)])
  end
  return antidiagonal
end

print(char_table_to_str(get_antidiagonal(example_matrix, 18)))

-- Total number of diagonals for a square matrix of size n
function number_of_diagonals (n)
  return (n - 1) * 2 + 1
end

-- Iterator on TL to BR strings
function TL_BR_strings (matrix)
  local k = 0
  local n = number_of_diagonals(#matrix)
  return function ()
    k = k + 1
    if k <= n then
      return char_table_to_str(get_diagonal(matrix, k))
    end
  end
end

example_diag_iter = TL_BR_strings(example_matrix)
print("\nDiagonals of the example matrix: ")
for diagonal in example_diag_iter do
  print(diagonal)
end

-- Iterator on BR to TL strings
function BR_TL_strings (matrix)
  local k = 0
  local n = number_of_diagonals(#matrix)
  return function ()
    k = k + 1
    if k <= n then
      return string.reverse(char_table_to_str(get_diagonal(matrix, k)))
    end
  end
end

-- Iterator on TR to BL strings
function TR_BL_strings (matrix)
  local k = 0
  local n = number_of_diagonals(#matrix)
  return function ()
    k = k + 1
    if k <= n then
      return char_table_to_str(get_antidiagonal(matrix, k))
    end
  end
end

-- Iterator on BL to TR strings
function BL_TR_strings (matrix)
  local k = 0
  local n = number_of_diagonals(#matrix)
  return function ()
    k = k + 1
    if k <= n then
      return string.reverse(char_table_to_str(get_antidiagonal(matrix, k)))
    end
  end
end

-- Count the number of XMAS in a string.
function count_xmas (str)
  local matches = collect_iter(string.gmatch(str, "XMAS"))
  return #matches
end

print(count_xmas("STXMASEEXMASIEIEXMAS"))


-- Count the number of XMAS in the matrix, in any order.
function count_matrix_xmas (matrix)
  local count = 0
  for _, iter_factory in ipairs({left_right_strings,
                                 right_left_strings,
                                 top_bottom_strings,
                                 bottom_top_strings,
                                 TL_BR_strings,
                                 BR_TL_strings,
                                 TR_BL_strings,
                                 BL_TR_strings}) do
    local string_iter = iter_factory(matrix)
    for str in string_iter do
      count = count + count_xmas(str)
    end
  end
  return count
end

print("Part 1 example count: ", count_matrix_xmas(example_matrix))
print("Part 1 count: ", count_matrix_xmas(input_matrix))

-- # Part 2
-- We just iterate over every 3x3 element in the interior of the matrix
-- and check whether it is an X-MAS.

-- Check if a 3x3 matrix is an X-MAS.
function element_is_xmas (matrix_element)
  local diagonal = get_diagonal(matrix_element, 3)
  local antidiagonal = get_antidiagonal(matrix_element, 3)
  local string1 = char_table_to_str(diagonal)
  local string2 = string.reverse(string1)
  local string3 = char_table_to_str(antidiagonal)
  local string4 = string.reverse(string3)
  local count = 0
  for _, str in ipairs({string1, string2, string3, string4}) do
    if string.find(str, "MAS") then
      count = count + 1
    end
  end
  return (count == 2)
end

example_x_mas_str = "M.S\n"
                 .. ".A.\n"
                 .. "M.S\n"
example_x_mas_matrix = str_to_matrix(example_x_mas_str)

print("element_is_xmas: ", element_is_xmas(example_x_mas_matrix))

-- Cut a 3x3 matrix around a given position in a 2D matrix.
function extract_3_element (matrix, i_center, j_center)
  local matrix_element = {}
  for i = i_center - 1, i_center + 1 do
    local line = {}
    for j = j_center - 1, j_center + 1 do
      table.insert(line, matrix[i][j])
    end
    table.insert(matrix_element, line)
  end
  return matrix_element
end

-- Iterator to all 3x3 center indices in a matrix
function center_indices (matrix)
  local n = #matrix
  local i = 2
  local j = 1
  return function ()
    j = j + 1
    if j >= n then
      j = 2
      i = i + 1
    end
    if i <= n - 1 then
      return i, j
    end
  end
end

example_indices_iter = center_indices(example_x_mas_matrix)
for i, j in example_indices_iter do
  print(i, j)
end

-- Iterator factory to all 3x3 elements in a matrix
function element3_iter (matrix)
  local indices_iter = center_indices(matrix)
  return function ()
    local i_center = 0
    local j_center = 0
    i_center, j_center = indices_iter()
    if i_center and j_center then
      return extract_3_element(matrix, i_center, j_center)
    end
  end
end

-- example_mat3_iter = element3_iter(example_matrix)
-- for mat in example_mat3_iter do
--   for _, row in ipairs(mat) do
--     print(char_table_to_str(row))
--   end
--   print()
-- end

-- Count the number of x-mas in the matrix
function count_x_mas (matrix)
  mat3_iter = element3_iter(matrix)
  local count = 0
  for mat3 in mat3_iter do
    if element_is_xmas(mat3) then
      count = count + 1
    end
  end
  return count
end

print("Part 2 example count: ", count_x_mas(example_matrix))
print("Part 2 input count: ", count_x_mas(input_matrix))
