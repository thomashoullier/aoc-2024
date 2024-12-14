-- Generic utilities
local utils = {}

-- Parse a text file to a string (including all line breaks).
function utils.file_to_string (filepath)
  local file = io.open(filepath)
  local str = file:read("*a")
  file:close()
  return str
end

-- Iterator on the lines of a string. Skips double line breaks.
function utils.lines (str)
  return string.gmatch(str, "[^\n]+")
end

-- Make a copy of a table (shallow copy).
function utils.copy_table (tab)
  local ctab = {}
  for k, v in pairs(tab) do
    ctab[k] = v
  end
  return ctab
end

-- Collect on the elements returned by an iterator into a table.
function utils.collect_iter (iter)
  local tab = {}
  for v in iter do
    table.insert(tab, v)
  end
  return tab
end

-- Iterator to the characters in a string.
function utils.str_chars (str)
  return str:gmatch"."
end

-- Iterator over successive numbers in a string
function utils.integers (str)
  return str:gmatch"%d+"
end

-- Convert a string (with line breaks) to a 2D matrix of characters.
-- TODO
function utils.str_to_matrix (str)
  local matrix = {}
  for line in utils.lines(str) do
    local char_line = utils.collect_iter(utils.str_chars(line))
    table.insert(matrix, char_line)
  end
  return matrix
end

-- Convert a string (with line breaks) to a 2D matrix of digits.
function utils.str_to_dig_matrix (str)
  local matrix = {}
  for line in utils.lines(str) do
    local row = {}
    for char in utils.str_chars(line) do
      table.insert(row, tonumber(char))
    end
    table.insert(matrix, row)
  end
  return matrix
end

-- Convert a matrix of characters to a string.
function utils.matrix_to_str (mat)
  local str = ""
  for _, row in ipairs(mat) do
    str = str .. table.concat(row, '') .. "\n"
  end
  return str
end

-- Print a 2D matrix of characters
function utils.print_matrix (mat) print(utils.matrix_to_str(mat)) end

-- Print a vector
function utils.print_vector (vec)
  print(table.concat(vec, ', '))
end

-- Deep copy a 2D matrix
function utils.copy_matrix (mat)
  local cpy_mat = {}
  for k, row in pairs(mat) do
    cpy_mat[k] = utils.copy_table(row)
  end
  return cpy_mat
end

-- Split a string on a pattern, return everything before and after
function utils.split_on_pattern (str, pattern)
  local n_pattern = string.len(pattern)
  local split_pos = string.find(str, pattern)
  local before_match = string.sub(str, 1, split_pos - 1)
  local after_match = string.sub(str, split_pos + n_pattern, #str)
  return before_match, after_match
end

-- Iterator for elements separated by a pattern
function utils.iter_on_separator (str, sep)
  return string.gmatch(str, "[^" .. sep .. "]+")
end

-- Iterator on blocks of text separated by a double linebreak.
function utils.iter_blocks (str)
  local current_split_position = 0
  local last_split_position = 0
  local last_block = true
  return function ()
    if current_split_position then
      last_split_position = current_split_position + 1
    end
    current_split_position = string.find(str, "\n\n", last_split_position)
    if current_split_position then
      current_split_position = current_split_position + 1
      return string.sub(str, last_split_position, current_split_position-2)
    elseif last_block then
      last_block = false
      return string.sub(str, last_split_position, #str-1)
    end
  end
end

-- Return the dimensions (shape) of a 2D matrix.
function utils.matrix_shape (matrix)
  return {#matrix, #(matrix[1])}
end

-- Are matrix indices {i_row, i_col} within the matrix bounds?
-- 1-based indexing.
function utils.indices_in_matrix (indices, mat_shape)
  local i_row = indices[1]
  local i_col = indices[2]
  local n_row = mat_shape[1]
  local n_col = mat_shape[2]
  return i_row >= 1 and i_row <= n_row and i_col >= 1 and i_col <= n_col
end

-- Iterator over the elements of a 2D matrix
function utils.iter_on_matrix (matrix)
  local shape = utils.matrix_shape(matrix)
  local i_row = 1
  local j_row = 0
  return function ()
    if j_row < shape[2] then -- next element in column order
      j_row = j_row + 1
    else -- next row
      i_row = i_row + 1
      j_row = 1
    end
    if i_row <= shape[1] then
      return matrix[i_row][j_row]
    end
  end
end

-- Iterator over the indices in a 2D matrix
function utils.iter_matrix_indices (matrix_dims)
  local i = 1
  local j = 0
  return function ()
    if j < matrix_dims[2] then
      j = j + 1
    else
      i = i + 1
      j = 1
    end
    if i <= matrix_dims[1] then
      return {i, j}
    end
  end
end

-- Add two vectors
function utils.add_vec (vec1, vec2)
  local res = {}
  for i = 1, #vec1 do
    table.insert(res, vec1[i] + vec2[i])
  end
  return res
end

-- Negate a vector
function utils.neg_vec (vec)
  local res = {}
  for _, v in ipairs(vec) do
    table.insert(res, -v)
  end
  return res
end

-- Subtract two vectors, vec1 - vec2
function utils.sub_vec (vec1, vec2)
  local neg_vec2 = utils.neg_vec(vec2)
  return utils.add_vec(vec1, neg_vec2)
end

-- Matrix indexing {i, j} to lexicographic indexing.
function utils.lex_index (position, matrix_dims)
  return (position[1] - 1) * matrix_dims[2] + position[2]
end

-- Convert lexicographic index to {i, j}
function utils.lex_to_index (lexi, matrix_dims)
  local i = ((lexi - 1) // matrix_dims[2]) + 1
  local j = math.floor(0.5 + math.fmod(lexi - 1, matrix_dims[2])) + 1
  return {i, j}
end

-- Create a matrix with the given 2D dimensions, filled with
-- the provided value.
function utils.full (matrix_dims, fill_value)
  local mat = {}
  for i = 1, matrix_dims[1] do
    local row = {}
    for j = 1, matrix_dims[2] do
      table.insert(row, fill_value)
    end
    table.insert(mat, row)
  end
  return mat
end

-- Create a matrix with the given 2D dimensions, filled with zeros
function utils.zeros (matrix_dims) return utils.full(matrix_dims, 0) end

-- Pad a 2D matrix with a value, the padding has a thickness of one.
function utils.pad (matrix, value_pad)
  local matrix_dims = utils.matrix_shape(matrix)
  local padded_dims = {matrix_dims[1] + 2, matrix_dims[2] + 2}
  local padded_matrix = utils.full(padded_dims, value_pad)
  for i = 1, matrix_dims[1] do
    for j = 1, matrix_dims[2] do
      padded_matrix[i + 1][j + 1] = matrix[i][j]
    end
  end
  return padded_matrix
end

-- Iterator over the indices on the interior of a padded matrix
function utils.iter_interior_indices (matrix_dims)
  local i = 2
  local j = 1
  return function ()
    if j < matrix_dims[2] - 1 then
      j = j + 1
    else
      i = i + 1
      j = 2
    end
    if i <= matrix_dims[1] - 1 then
      return {i, j}
    end
  end
end

-- Determinant of a 2x2 matrix
function utils.matrix_22_determinant (matrix)
  return matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1]
end

-- Inverse of a 2x2 matrix
function utils.matrix_22_inverse (matrix)
  local det = utils.matrix_22_determinant(matrix)
  local inverse = utils.copy_matrix(matrix)
  inverse[1][1] = matrix[2][2] / det
  inverse[1][2] = - matrix[1][2] / det
  inverse[2][1] = - matrix[2][1] / det
  inverse[2][2] = matrix[1][1] / det
  return inverse
end

-- Multiply a matrix by a vector. 2D case only
function utils.matrix_22_vec_mul (matrix, vec)
  local res = {}
  table.insert(res, matrix[1][1] * vec[1] + matrix[1][2] * vec[2])
  table.insert(res, matrix[2][1] * vec[1] + matrix[2][2] * vec[2])
  return res
end

-- Check if a float number is close enough to an integer
function utils.close_to_int (num, tol)
  local closest_int = math.floor(num + 0.5)
  local gap = math.abs(closest_int - num)
  return gap < tol
end

return utils
