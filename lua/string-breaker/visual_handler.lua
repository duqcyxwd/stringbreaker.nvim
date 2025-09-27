local M = {}


function M.one_to_zero_index_position(position)
  local start_row, start_col, end_row, end_col = position[1], position[2], position[3], position[4]
  -- Convert 1-indexed to 0-indexed
  --(last col is excludesive)
  return { start_row - 1, start_col - 1, end_row - 1, end_col }
end

function M.zero_to_one_index_position(position)
  local start_row, start_col, end_row, end_col = position[1], position[2], position[3], position[4]
  -- Convert 1-indexed to 0-indexed
  return { start_row + 1, start_col + 1, end_row + 1, end_col }
end

function M.get_visual_selection_range()
  local function compare_positions(pos1, pos2)
    -- Compare by line first, and by column second
    if pos1[2] < pos2[2] or (pos1[2] == pos2[2] and pos1[3] < pos2[3]) then
      return true
    else
      return false
    end
  end

  local visual_pos = vim.fn.getpos('v')
  local cursor_pos = vim.fn.getpos('.')

  local first_pos, sec_pos

  -- Compare and assign
  if compare_positions(visual_pos, cursor_pos) then
    first_pos, sec_pos = visual_pos, cursor_pos
  else
    first_pos, sec_pos = cursor_pos, visual_pos
  end

  -- get vm mode
  local mode = vim.fn.mode()

  if mode == "V" then
    print(first_pos[2], first_pos[3], sec_pos[2], sec_pos[3])
    first_pos[3] = 1
    local line_content = vim.fn.getline(sec_pos[2])
    sec_pos[3] = #line_content
  end

  return M.one_to_zero_index_position({ first_pos[2], first_pos[3], sec_pos[2], sec_pos[3] })
end

-- Get visual selection text and position information
-- @return table|nil Visual selection information or nil if no selection
function M.get_visual_selection()
  -- Check if currently in visual mode
  local mode = vim.fn.mode()
  if mode ~= 'v' and mode ~= 'V' and mode ~= '\22' then -- \22 is Ctrl-V
    return nil
  end
  local bufnr = vim.api.nvim_get_current_buf()

  local selection_range = M.get_visual_selection_range()
  local start_row, start_col, end_row, end_col = unpack(selection_range)
  local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
  local content = table.concat(lines, "\n")


  -- Validate content is not empty
  if not content or content == "" then
    return nil
  end


  return {
    content = content,
    start_pos = { start_row + 1, start_col },
    end_pos = { end_row + 1, end_col },
    mode = mode,
    bufnr = bufnr
  }
end

-- Validate if visual selection is valid
-- @param selection table Visual selection information
-- @return boolean Whether selection is valid
function M.validate_selection(selection)
  if not selection then
    return false
  end

  -- Check required fields
  if not selection.content or not selection.start_pos or not selection.end_pos or not selection.bufnr then
    return false
  end

  -- Check content is not empty
  if selection.content == "" then
    return false
  end

  -- Check position information is valid
  if not selection.start_pos[1] or not selection.start_pos[2] or
      not selection.end_pos[1] or not selection.end_pos[2] then
    return false
  end

  -- Check buffer is valid
  if not vim.api.nvim_buf_is_valid(selection.bufnr) then
    return false
  end

  return true
end

-- Detect quote type of selected content
-- @param content string Selected content
-- @return string Quote type
local function detect_quote_type(content)
  if not content or content == '' then
    return ''
  end

  -- Check if content is surrounded by quotes
  local first_char = string.sub(content, 1, 1)
  local last_char = string.sub(content, -1)

  -- If first and last characters are the same and are quotes, determine quote type
  if (first_char == '"' or first_char == "'" or first_char == '`') and
      last_char == first_char then
    return first_char
  end

  -- If content starts with quote but is not fully surrounded by quotes, try to detect quote type
  if first_char == '"' or first_char == "'" or first_char == '`' then
    return first_char
  end

  -- Default return empty string, indicating no quotes
  return ''
end

-- Extract content inside quotes
-- @param content string Complete content
-- @param quote_type string Quote type
-- @return string Content inside quotes
local function extract_inner_content(content, quote_type)
  if not content or content == '' or quote_type == '' then
    return content
  end

  -- If content is surrounded by quotes, extract inner content
  if #content >= 2 then
    local first_char = string.sub(content, 1, 1)
    local last_char = string.sub(content, -1)

    if first_char == quote_type and last_char == quote_type then
      return string.sub(content, 2, -2)
    end
  end

  return content
end

-- Convert visual selection to string information format
-- @param selection table Visual selection information
-- @return table String information format
function M.selection_to_string_info(selection)
  if not M.validate_selection(selection) then
    return nil
  end

  -- Detect quote type
  local quote_type = detect_quote_type(selection.content)
  local inner_content = extract_inner_content(selection.content, quote_type)

  return {
    content = selection.content,
    inner_content = inner_content,
    start_pos = selection.start_pos,
    end_pos = selection.end_pos,
    quote_type = quote_type,
    source_type = 'visual',
    mode_info = {
      visual_mode = selection.mode,
      bufnr = selection.bufnr
    }
  }
end

-- Get current visual selection and convert to string information
-- @return table|nil String information or nil
function M.get_current_visual_string_info()
  local selection = M.get_visual_selection()
  if not selection then
    return nil
  end

  return M.selection_to_string_info(selection)
end

return M
