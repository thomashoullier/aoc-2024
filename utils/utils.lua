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

return utils
