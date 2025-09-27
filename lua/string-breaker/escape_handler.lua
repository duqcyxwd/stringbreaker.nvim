local M = {}

-- Unescape string (for editing)
-- Convert escape sequences to actual characters
function M.unescape(str)
  if not str or type(str) ~= 'string' then
    return ""
  end

  -- Handle empty string
  if str == "" then
    return ""
  end

  -- Handle common escape sequences
  -- Note: Must handle double backslashes first to avoid conflicts with other escape sequences
  local result = str

  -- Handle escape sequences in the correct order
  result = result:gsub("\\\\", "\x01")  -- Temporarily replace double backslashes with safe placeholder
  result = result:gsub("\\n", "\n")     -- Newline
  result = result:gsub("\\t", "\t")     -- Tab
  result = result:gsub("\\r", "\r")     -- Carriage return
  result = result:gsub("\\\"", "\"")    -- Double quote
  result = result:gsub("\\'", "'")      -- Single quote
  result = result:gsub("\\0", "\0")     -- Null character
  result = result:gsub("\x01", "\\")    -- Restore single backslash

  return result
end

-- Escape string (for saving back to original file)
-- Convert special characters to escape sequences
function M.escape(str, quote_type)
  if not str or type(str) ~= 'string' then
    return ""
  end

  -- Handle empty string
  if str == "" then
    return ""
  end

  quote_type = quote_type or "\""

  local result = str
  -- -- Backslashes must be handled first to avoid double escaping
  result = result:gsub("\\", "\\\\")
  result = result:gsub("\n", "\\n") -- Newline
  result = result:gsub("\t", "\\t") -- Tab
  result = result:gsub("\r", "\\r") -- Carriage return
  -- result = result:gsub("\0", "\\0")   -- Null character

  -- Escape corresponding quotes based on quote type
  if quote_type == "\"" then
    result = result:gsub("\"", "\\\"")
  elseif quote_type == "'" then
    result = result:gsub("'", "\\'")
  elseif quote_type == "`" then
    -- Template literals might need different handling
    -- For now, treat them like double quotes
    result = result:gsub("`", "\\`")
  end

  return result
end

return M
