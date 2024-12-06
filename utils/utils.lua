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

-- Deep copy a 2D matrix
function utils.copy_matrix (mat)
  local cpy_mat = {}
  for k, row in pairs(mat) do
    cpy_mat[k] = utils.copy_table(row)
  end
  return cpy_mat
end

return utils
