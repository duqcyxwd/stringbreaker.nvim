-- StringBreaker - Unified String Editing API
-- Provides a simple interface to edit, preview and manage string content

local M = {}

-- Internal module references
local string_detector = require('string-breaker.string_detector')
local visual_handler = require('string-breaker.visual_handler')
local escape_handler = require('string-breaker.escape_handler')
local buffer_manager = require('string-breaker.buffer_manager')

-- Configuration options
local config = {
  preview = {
    max_length = 1000, -- Maximum preview content length
    use_float = true,  -- Use floating window
    width = 80,        -- Floating window width
    height = 20        -- Floating window height
  }
}

-- Check if Tree-sitter is available and properly configured
local function check_treesitter()
  -- Check if nvim-treesitter is available
  local ok, ts = pcall(require, 'nvim-treesitter')
  if not ok then
    vim.notify(
      'String Editor: nvim-treesitter plugin is required but not installed. Please install nvim-treesitter first.',
      vim.log.levels.ERROR)
    return false
  end

  -- Check if ts_utils is available
  local ts_ok, ts_utils = pcall(require, 'nvim-treesitter.ts_utils')
  if not ts_ok and not ts.get_installed then
    vim.notify(
      'String Editor: nvim-treesitter.ts_utils or treesitter **main** branch is required but not available. Please ensure nvim-treesitter is properly configured.',
      vim.log.levels.ERROR)
    return false
  end

  -- Check if parser is available for current buffer
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

  if filetype == '' then
    vim.notify(
      'String Editor: No filetype detected for current buffer. Tree-sitter requires a valid filetype to parse strings.',
      vim.log.levels.WARN)
    return false
  end

  -- Try to get parser for current filetype
  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, filetype)
  if not parser_ok or not parser then
    vim.notify(
      string.format(
        'String Editor: No Tree-sitter parser available for filetype "%s". Please install the parser or check your Tree-sitter configuration.',
        filetype), vim.log.levels.WARN)
    return false
  end

  return true
end


-- Handle string detection in normal mode
-- @return table|nil String information or error information
function M._handle_normal_mode()
  local string_info, detection_err = string_detector.detect_string_at_cursor()
  if detection_err then
    return detection_err
  end

  if not string_info then
    return {
      success = false,
      error_code = 'NO_STRING_FOUND',
      message =
      'No string found at cursor position. Please place cursor inside string or use visual mode to select text.',
      suggestions = {
        'Move cursor inside string quotes',
        'Use visual mode to select text for editing',
        'Check if current file syntax is properly recognized'
      }
    }
  end

  -- Add source type information
  string_info.source_type = 'treesitter'

  return {
    success = true,
    data = string_info
  }
end

-- Handle text selection in visual mode
-- @return table|nil String information or error information
function M._handle_visual_mode()
  local string_info = visual_handler.get_current_visual_string_info()
  if not string_info then
    return {
      success = false,
      error_code = 'INVALID_SELECTION',
      message = 'Invalid visual selection. Please select valid text content.',
      suggestions = {
        'Ensure non-empty text content is selected',
        'Check if selection range is correct',
        'Re-select text'
      }
    }
  end

  return {
    success = true,
    data = string_info
  }
end

-- Start editing string (supports normal mode and visual mode)
-- @return table API response
function M.break_string()
  local success, result = pcall(function()
    -- Check if current buffer is modifiable
    local current_bufnr = vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_get_option(current_bufnr, 'modifiable') then
      return {
        success = false,
        error_code = 'BUFFER_NOT_MODIFIABLE',
        message = 'Current buffer is not modifiable. Cannot edit string in read-only buffer.',
        suggestions = {
          'Check if file is read-only',
          'Ensure you have file write permissions',
          'Try using :set modifiable command'
        }
      }
    end

    -- Detect current mode and get string information
    local mode = vim.fn.mode()
    local string_result

    if mode == 'v' or mode == 'V' or mode == '\22' then
      string_result = M._handle_visual_mode()
    elseif mode == 'n' then
      string_result = M._handle_normal_mode()
    else
      return {
        success = false,
        error_code = 'UNSUPPORTED_MODE',
        message = 'Unsupported editor mode. Please use this feature in normal mode or visual mode.',
        suggestions = {
          'Press Esc key to return to normal mode',
          'Use v key to enter visual mode and select text',
          'Check current editor state'
        }
      }
    end

    if not string_result.success then
      return string_result
    end

    local string_info = string_result.data

    -- Validate string content
    if not string_info.inner_content or string_info.inner_content == '' then
      return {
        success = false,
        error_code = 'EMPTY_CONTENT',
        message = 'Empty string detected. No content to edit.',
        suggestions = {
          'Select text that contains content',
          'Check if string actually contains text',
          'Try selecting a larger text range'
        }
      }
    end

    -- Check string size (prevent performance issues)
    if #string_info.inner_content > 10000 then
      local choice = vim.fn.confirm(
        'StringBreaker: This string is large (' ..
        #string_info.inner_content .. ' characters). Editing may be slow. Continue?',
        '&Yes\n&No',
        2
      )
      if choice ~= 1 then
        return {
          success = false,
          error_code = 'USER_CANCELLED',
          message = 'User cancelled the editing operation.',
          suggestions = {}
        }
      end
    end

    -- Unescape string content for editing
    local unescaped_content = escape_handler.unescape(string_info.inner_content)

    -- Prepare source information
    local source_info = {
      bufnr = current_bufnr,
      start_pos = string_info.start_pos,
      end_pos = string_info.end_pos,
      quote_type = string_info.quote_type or '',
      source_type = string_info.source_type,
      original_content = string_info.content
    }

    -- Create editing buffer
    local edit_bufnr = buffer_manager.create_edit_buffer(unescaped_content, source_info)

    if edit_bufnr then
      return {
        success = true,
        message = 'String opened for editing. Use :SaveString to save changes or close buffer to cancel editing.',
        data = {
          edit_buffer = edit_bufnr,
          source_type = string_info.source_type,
          content_length = #unescaped_content
        }
      }
    else
      return {
        success = false,
        error_code = 'BUFFER_CREATION_FAILED',
        message = 'Failed to create editing buffer. Please try again.',
        suggestions = {
          'Check memory usage',
          'Restart Neovim and try again',
          'Check plugin configuration'
        }
      }
    end
  end)

  if not success then
    return {
      success = false,
      error_code = 'UNEXPECTED_ERROR',
      message = 'Unexpected error occurred while editing string: ' .. tostring(result),
      suggestions = {
        'Check plugin installation and configuration',
        'Check Neovim logs for detailed information',
        'Restart Neovim and try again'
      }
    }
  end

  -- For debug
  -- vim.notify(result.message, vim.log.levels.INFO)
  -- vim.notify(vim.inspect(result), vim.log.levels.INFO)

  return result
end

-- Show preview content
-- @param content string Content to preview
-- @param source_type string Content source type
local function show_preview(content, source_type)
  -- Limit preview content length
  local preview_content = content
  if #content > config.preview.max_length then
    preview_content = string.sub(content, 1, config.preview.max_length) ..
        '\n\n[Content truncated - Total length: ' .. #content .. ' characters]'
  end

  if config.preview.use_float and #preview_content > 100 then
    -- Use floating window to display longer content
    M._show_float_preview(preview_content, source_type)
  elseif #preview_content <= 200 then
    -- Use notification to display short content
    vim.notify('StringBreaker Preview (' .. source_type .. '):\n' .. preview_content, vim.log.levels.INFO)
  else
    -- Use echo area to display medium length content
    vim.cmd('echo "StringBreaker Preview (' .. source_type .. '):"')
    vim.cmd('echo ' .. vim.fn.string(preview_content))
  end
end

-- Helper: Select the updated range of text
-- @param start_row number 0-indexed start row
-- @param start_col number 0-indexed start column
-- @param replacement_lines table List of replacement lines
-- @param mode string Previous editor mode
local function select_updated_range(start_row, start_col, replacement_lines, mode)
  -- Calculate new end position
  local new_end_row = start_row + #replacement_lines - 1
  local new_end_col
  if #replacement_lines == 1 then
    new_end_col = start_col + #replacement_lines[1]
  else
    new_end_col = #replacement_lines[#replacement_lines]
  end

  -- If in visual mode, return to normal mode first
  if mode == 'v' or mode == 'V' or mode == '\22' then
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    vim.cmd('normal! o')
    local cursor_end_col = new_end_col > 0 and new_end_col - 1 or 0
    vim.api.nvim_win_set_cursor(0, { new_end_row + 1, cursor_end_col })
  else
    -- NORMAL MODE: Select the updated text
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    vim.cmd('normal! v')
    local cursor_end_col = new_end_col > 0 and new_end_col - 1 or 0
    vim.api.nvim_win_set_cursor(0, { new_end_row + 1, cursor_end_col })
  end
end

-- Show floating window preview
-- @param content string Preview content
-- @param source_type string Content source type
function M._show_float_preview(content, source_type)
  -- Split content into lines
  local lines = vim.split(content, '\n', { plain = true })

  -- Calculate window dimensions
  local width = math.min(config.preview.width, vim.o.columns - 4)
  local height = math.min(config.preview.height, #lines + 2, vim.o.lines - 4)

  -- Calculate window position (centered)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create preview buffer
  local preview_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(preview_bufnr, 0, -1, false, lines)

  -- Set buffer options
  -- vim.api.nvim_buf_set_option(preview_bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(preview_bufnr, 'swapfile', false)
  vim.api.nvim_buf_set_option(preview_bufnr, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(preview_bufnr, 'filetype', 'text')
  vim.api.nvim_buf_set_option(preview_bufnr, 'modifiable', false)

  -- Create floating window
  local win_config = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' StringBreaker Preview (' .. source_type .. ') ',
    title_pos = 'center'
  }

  local preview_winnr = vim.api.nvim_open_win(preview_bufnr, false, win_config)

  -- Set window options
  vim.api.nvim_win_set_option(preview_winnr, 'wrap', true)
  vim.api.nvim_win_set_option(preview_winnr, 'linebreak', true)

  -- Set keymaps to close preview
  local opts = { buffer = preview_bufnr, silent = true }
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(preview_winnr) then
      vim.api.nvim_win_close(preview_winnr, true)
    end
  end, opts)

  vim.keymap.set('n', '<Esc>', function()
    if vim.api.nvim_win_is_valid(preview_winnr) then
      vim.api.nvim_win_close(preview_winnr, true)
    end
  end, opts)

  -- Auto close preview (after 5 seconds or when losing focus)
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(preview_winnr) then
      vim.api.nvim_win_close(preview_winnr, true)
    end
  end, 5000)

  -- Show usage hint
  vim.notify('Preview displayed. Press q or Esc to close, auto-closes after 5 seconds.', vim.log.levels.INFO)
end

-- Preview string content (without opening editor)
-- @return table API response
function M.preview()
  local success, result = pcall(function()
    -- Detect current mode and get string information
    local mode = vim.fn.mode()
    local string_result

    if mode == 'v' or mode == 'V' or mode == '\22' then
      string_result = M._handle_visual_mode()
    elseif mode == 'n' then
      string_result = M._handle_normal_mode()
    else
      return {
        success = false,
        error_code = 'UNSUPPORTED_MODE',
        message = 'Unsupported editor mode. Please use preview feature in normal mode or visual mode.'
      }
    end

    if not string_result.success then
      return string_result
    end

    local string_info = string_result.data

    -- Validate string content
    if not string_info.inner_content or string_info.inner_content == '' then
      return {
        success = false,
        error_code = 'EMPTY_CONTENT',
        message = 'No content to preview.'
      }
    end

    -- Unescape string content
    local unescaped_content = escape_handler.unescape(string_info.inner_content)

    -- Show preview
    show_preview(unescaped_content, string_info.source_type)

    return {
      success = true,
      message = 'String preview displayed.',
      data = {
        content = unescaped_content,
        source_type = string_info.source_type,
        length = #unescaped_content
      }
    }
  end)

  if not success then
    return {
      success = false,
      error_code = 'UNEXPECTED_ERROR',
      message = 'Unexpected error occurred while previewing string: ' .. tostring(result)
    }
  end

  return result
end

-- Synchronize buffer content with the original file
-- @return table API response
function M.sync()
  -- Use pcall for comprehensive error handling
  local success, result = pcall(function()
    -- Get current buffer number
    local current_bufnr = vim.api.nvim_get_current_buf()

    -- Check if current buffer is a stringBreaker buffer
    local filetype = vim.api.nvim_buf_get_option(current_bufnr, 'filetype')
    if filetype ~= 'stringBreaker' then
      return {
        success = false,
        error_code = 'NOT_IN_EDIT_BUFFER',
        message = 'sync() can only be used in string editor buffers. Current buffer type: ' .. (filetype or 'none'),
        suggestions = {
          'Ensure this function is called in string editor buffer',
          'Use break_string() function to start editing string'
        }
      }
    end

    -- Get source information for this buffer
    local source_info = buffer_manager.get_source_info(current_bufnr)
    if not source_info then
      return {
        success = false,
        error_code = 'NO_SOURCE_INFO',
        message = 'No source information found for this buffer. The original file reference may have been lost.',
        suggestions = {
          'Try restarting the string editing session',
          'Check if original buffer still exists'
        }
      }
    end

    -- Validate that the original buffer still exists and is valid
    if not vim.api.nvim_buf_is_valid(source_info.bufnr) then
      return {
        success = false,
        error_code = 'INVALID_SOURCE_BUFFER',
        message = 'Original buffer is no longer valid. Cannot synchronize changes.',
        suggestions = {
          'Original buffer may have been closed',
          'Try canceling and restarting the editing session'
        }
      }
    end

    -- Check if original buffer is still modifiable
    if not vim.api.nvim_buf_get_option(source_info.bufnr, 'modifiable') then
      return {
        success = false,
        error_code = 'BUFFER_NOT_MODIFIABLE',
        message = 'Original buffer is no longer modifiable. Cannot synchronize changes.',
        suggestions = {
          'Check if file is read-only',
          'Ensure you have file write permissions',
          'Try using :set modifiable command'
        }
      }
    end

    -- Get content from edit buffer
    local lines = vim.api.nvim_buf_get_lines(current_bufnr, 0, -1, false)
    local edited_content = table.concat(lines, '\n')

    -- Check if content has actually changed
    local original_unescaped = escape_handler.unescape(source_info.original_content and
      source_info.original_content:sub(2, -2) or '')
    if edited_content == original_unescaped then
      return {
        success = true,
        message = 'No changes detected. Content is already synchronized.',
        data = {
          changed = false,
          content_length = #edited_content
        }
      }
    end

    -- Escape the content for saving back to original file
    local escaped_content = escape_handler.escape(edited_content, source_info.quote_type)

    -- Add quotes back to the escaped content
    local full_content = source_info.quote_type .. escaped_content .. source_info.quote_type

    -- Validate the replacement positions are still valid
    local original_lines = vim.api.nvim_buf_line_count(source_info.bufnr)
    if source_info.start_pos[1] > original_lines or source_info.end_pos[1] > original_lines then
      return {
        success = false,
        error_code = 'INVALID_POSITION',
        message = 'Original file has been modified. Cannot safely synchronize changes to the original location.',
        suggestions = {
          'Original file may have been edited externally',
          'Try canceling and restarting the editing session',
          'Check if file content has changed'
        }
      }
    end

    -- Replace the string content in the original file
    -- Convert to 0-based positions for nvim_buf_set_text
    local start_row = source_info.start_pos[1] - 1
    local start_col = source_info.start_pos[2]
    local end_row = source_info.end_pos[1] - 1
    local end_col = source_info.end_pos[2]

    -- Split the full content into lines for replacement
    local replacement_lines = vim.split(full_content, '\n', { plain = true })

    -- Replace the text in the original buffer
    vim.api.nvim_buf_set_text(source_info.bufnr, start_row, start_col, end_row, end_col, replacement_lines)

    -- Update source_info with new end position after replacement
    local new_end_row = start_row + #replacement_lines - 1
    local new_end_col
    if #replacement_lines == 1 then
      -- Single line replacement: end column = start column + length of new content
      new_end_col = start_col + #replacement_lines[1]
    else
      -- Multi-line replacement: end column = length of last line
      new_end_col = #replacement_lines[#replacement_lines]
    end

    -- Update the stored source_info with new positions and content
    source_info.end_pos = { new_end_row + 1, new_end_col } -- Convert back to 1-based
    source_info.original_content = full_content
    buffer_manager.store_source_info(current_bufnr, source_info)

    return {
      success = true,
      message = 'Content synchronized successfully.',
      data = {
        changed = true,
        content_length = #edited_content,
        lines_replaced = #replacement_lines,
        new_end_pos = source_info.end_pos
      }
    }
  end)

  if not success then
    -- Provide more specific error messages
    local error_msg = tostring(result)
    if error_msg:find('Invalid buffer') then
      return {
        success = false,
        error_code = 'BUFFER_ERROR',
        message = 'Buffer operation failed. The buffer may have been closed or corrupted.',
        suggestions = {
          'Try restarting the editing session',
          'Check if buffer is still valid'
        }
      }
    elseif error_msg:find('position') then
      return {
        success = false,
        error_code = 'POSITION_ERROR',
        message = 'Position error occurred. The original file may have been modified.',
        suggestions = {
          'Check if original file has been modified',
          'Try restarting the editing session'
        }
      }
    else
      return {
        success = false,
        error_code = 'UNEXPECTED_ERROR',
        message = 'Unexpected error occurred while synchronizing: ' .. error_msg,
        suggestions = {
          'Check plugin installation and configuration',
          'Check Neovim logs for detailed information',
          'Try restarting Neovim'
        }
      }
    end
  end

  return result
end

-- Save string to original file and close the editor buffer
-- @return table API response
function M.save()
  -- Use pcall for comprehensive error handling
  local success, result = pcall(function()
    -- Get current buffer number
    local current_bufnr = vim.api.nvim_get_current_buf()

    -- Check if current buffer is a stringBreaker buffer
    local filetype = vim.api.nvim_buf_get_option(current_bufnr, 'filetype')
    if filetype ~= 'stringBreaker' then
      return {
        success = false,
        error_code = 'NOT_IN_EDIT_BUFFER',
        message = 'save() can only be used in string editor buffers. Current buffer type: ' .. (filetype or 'none'),
        suggestions = {
          'Ensure this function is called in string editor buffer',
          'Use break_string() function to start editing string'
        }
      }
    end

    -- First, synchronize the content with the original file
    local sync_result = M.sync()
    if not sync_result.success then
      return sync_result
    end

    -- Get source information for closing the buffer
    local source_info = buffer_manager.get_source_info(current_bufnr)
    if not source_info then
      return {
        success = false,
        error_code = 'NO_SOURCE_INFO',
        message =
        'No source information found for this buffer. Content was synchronized but buffer cannot be closed properly.',
        suggestions = {
          'Manually close the buffer',
          'Check if original buffer still exists'
        }
      }
    end

    -- Close the edit buffer
    buffer_manager.get_content_and_close(current_bufnr)

    -- Switch to the original buffer if it's still valid
    if vim.api.nvim_buf_is_valid(source_info.bufnr) then
      vim.api.nvim_set_current_buf(source_info.bufnr)
    end

    return {
      success = true,
      message = sync_result.data.changed and 'String saved and editor closed successfully.' or
          'No changes detected. Editor closed without modifying original file.',
      data = {
        synchronized = sync_result.data.changed,
        content_length = sync_result.data.content_length,
        lines_replaced = sync_result.data.lines_replaced or 0
      }
    }
  end)

  if not success then
    -- Provide more specific error messages
    local error_msg = tostring(result)
    if error_msg:find('Invalid buffer') then
      vim.notify('String Editor: Buffer operation failed. The buffer may have been closed or corrupted.',
        vim.log.levels.ERROR)
    elseif error_msg:find('position') then
      vim.notify('String Editor: Position error occurred. The original file may have been modified.',
        vim.log.levels.ERROR)
    else
      vim.notify('String Editor: Unexpected error occurred while saving: ' .. error_msg, vim.log.levels.ERROR)
    end

    return {
      success = false,
      error_code = 'UNEXPECTED_ERROR',
      message = 'Unexpected error occurred while saving: ' .. error_msg
    }
  end

  return result
end

-- Cancel editing without saving changes
-- @return table API response
function M.cancel()
  local success, result = pcall(function()
    local current_bufnr = vim.api.nvim_get_current_buf()

    -- Check if in string editing buffer
    local filetype = vim.api.nvim_buf_get_option(current_bufnr, 'filetype')
    if filetype ~= 'stringBreaker' then
      return {
        success = false,
        error_code = 'NOT_IN_EDIT_BUFFER',
        message = 'cancel() can only be used in string editing buffer.',
        suggestions = {
          'Ensure this function is called in string editing buffer',
          'Use break() or break_string() function to start editing string'
        }
      }
    end

    -- Get source information
    local source_info = buffer_manager.get_source_info(current_bufnr)
    if source_info then
      -- Close editing buffer
      buffer_manager.get_content_and_close(current_bufnr)

      -- Switch back to original buffer
      if vim.api.nvim_buf_is_valid(source_info.bufnr) then
        vim.api.nvim_set_current_buf(source_info.bufnr)
      end
    else
      -- Force close buffer
      vim.api.nvim_buf_delete(current_bufnr, { force = true })
    end

    return {
      success = true,
      message = 'Editing cancelled. Original file unchanged.'
    }
  end)

  if not success then
    return {
      success = false,
      error_code = 'CANCEL_FAILED',
      message = 'Error occurred while cancelling edit: ' .. tostring(result)
    }
  end

  return result
end

-- Configure StringBreaker
-- @param opts table Configuration options
function M.setup(opts)
  if opts then
    config = vim.tbl_deep_extend('force', config, opts)
  end
end

-- Escape selected string content
-- @param quote_type string Quote type parameter ('single' or 'double')
-- @return table API response
function M.escape_string(quote_type)
  local success, result = pcall(function()
    -- Check if current buffer is modifiable
    local current_bufnr = vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_get_option(current_bufnr, 'modifiable') then
      return {
        success = false,
        error_code = 'BUFFER_NOT_MODIFIABLE',
        message = 'Current buffer is not modifiable. Cannot escape string in read-only buffer.',
        suggestions = {
          'Check if file is read-only',
          'Ensure you have file write permissions',
          'Try using :set modifiable command'
        }
      }
    end

    -- Detect current mode and get string information
    local mode = vim.fn.mode()
    local string_result

    if mode == 'v' or mode == 'V' or mode == '\22' then
      string_result = M._handle_visual_mode()
    elseif mode == 'n' then
      string_result = M._handle_normal_mode()
    else
      return {
        success = false,
        error_code = 'UNSUPPORTED_MODE',
        message = 'Unsupported editor mode. Please use this feature in normal mode or visual mode.',
        suggestions = {
          'Press Esc key to return to normal mode',
          'Use v key to enter visual mode and select text',
          'Check current editor state'
        }
      }
    end

    if not string_result.success then
      return string_result
    end

    local string_info = string_result.data

    -- Validate string content
    if not string_info.inner_content or string_info.inner_content == '' then
      return {
        success = false,
        error_code = 'EMPTY_CONTENT',
        message = 'Empty content detected. No content to escape.',
        suggestions = {
          'Select text that contains content',
          'Check if selection actually contains text',
          'Try selecting a larger text range'
        }
      }
    end

    -- Determine quote type for escaping
    local escape_quote_type = '"' -- default to double quote
    if quote_type then
      if quote_type == 'single' then
        escape_quote_type = "'"
      elseif quote_type == 'double' then
        escape_quote_type = '"'
      end
    end

    -- Escape the content
    local escaped_content = escape_handler.escape(string_info.inner_content, escape_quote_type)

    -- Replace the content in the buffer
    local start_row = string_info.start_pos[1] - 1
    local start_col = string_info.start_pos[2]
    local end_row = string_info.end_pos[1] - 1
    local end_col = string_info.end_pos[2]

    -- For visual mode, we want to replace just the selected content
    if mode == 'v' or mode == 'V' or mode == '\22' then
      start_col = string_info.start_pos[2]
      end_col = string_info.end_pos[2]
    else
      -- For normal mode with treesitter, replace just the inner content
      start_col = string_info.start_pos[2] + 1 -- Skip opening quote
      end_col = string_info.end_pos[2] - 1     -- Skip closing quote
    end

    -- Split the escaped content into lines for replacement
    local replacement_lines = vim.split(escaped_content, '\n', { plain = true })

    -- Replace the text in the buffer
    vim.api.nvim_buf_set_text(current_bufnr, start_row, start_col, end_row, end_col, replacement_lines)

    select_updated_range(start_row, start_col, replacement_lines, mode)

    return {
      success = true,
      message = 'String content escaped successfully using ' .. (quote_type or 'double') .. ' quote rules.',
      data = {
        quote_type = escape_quote_type,
        original_length = #string_info.inner_content,
        escaped_length = #escaped_content,
        mode = mode
      }
    }
  end)

  if not success then
    return {
      success = false,
      error_code = 'UNEXPECTED_ERROR',
      message = 'Unexpected error occurred while escaping string: ' .. tostring(result),
      suggestions = {
        'Check plugin installation and configuration',
        'Check Neovim logs for detailed information',
        'Restart Neovim and try again'
      }
    }
  end

  return result
end

-- Unescape selected string content
-- @return table API response
function M.unescape_string()
  local success, result = pcall(function()
    -- Check if current buffer is modifiable
    local current_bufnr = vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_get_option(current_bufnr, 'modifiable') then
      return {
        success = false,
        error_code = 'BUFFER_NOT_MODIFIABLE',
        message = 'Current buffer is not modifiable. Cannot unescape string in read-only buffer.',
        suggestions = {
          'Check if file is read-only',
          'Ensure you have file write permissions',
          'Try using :set modifiable command'
        }
      }
    end

    -- Detect current mode and get string information
    local mode = vim.fn.mode()
    local string_result


    if mode == 'v' or mode == 'V' or mode == '\22' then
      string_result = M._handle_visual_mode()
    elseif mode == 'n' then
      string_result = M._handle_normal_mode()
    else
      return {
        success = false,
        error_code = 'UNSUPPORTED_MODE',
        message = 'Unsupported editor mode. Please use this feature in normal mode or visual mode.',
        suggestions = {
          'Press Esc key to return to normal mode',
          'Use v key to enter visual mode and select text',
          'Check current editor state'
        }
      }
    end

    if not string_result.success then
      return string_result
    end

    local string_info = string_result.data

    -- Validate string content
    if not string_info.inner_content or string_info.inner_content == '' then
      return {
        success = false,
        error_code = 'EMPTY_CONTENT',
        message = 'Empty content detected. No content to unescape.',
        suggestions = {
          'Select text that contains content',
          'Check if selection actually contains text',
          'Try selecting a larger text range'
        }
      }
    end

    -- Unescape the content
    local unescaped_content = escape_handler.unescape(string_info.inner_content)

    -- Replace the content in the buffer
    local start_row = string_info.start_pos[1] - 1
    local start_col = string_info.start_pos[2]
    local end_row = string_info.end_pos[1] - 1
    local end_col = string_info.end_pos[2]

    -- For visual mode, we want to replace just the selected content
    if mode == 'v' or mode == 'V' or mode == '\22' then
       start_col = string_info.start_pos[2]
       end_col = string_info.end_pos[2]
    else
      -- For normal mode with treesitter, replace just the inner content
      start_col = string_info.start_pos[2] + 1 -- Skip opening quote
      end_col = string_info.end_pos[2] - 1     -- Skip closing quote
    end

    -- Split the unescaped content into lines for replacement
    local replacement_lines = vim.split(unescaped_content, '\n', { plain = true })

    -- Replace the text in the buffer
    vim.api.nvim_buf_set_text(current_bufnr, start_row, start_col, end_row, end_col, replacement_lines)

    select_updated_range(start_row, start_col, replacement_lines, mode)

    return {
      success = true,
      message = 'String content unescaped successfully.',
      data = {
        original_length = #string_info.inner_content,
        unescaped_length = #unescaped_content,
        mode = mode
      }
    }
  end)

  if not success then
    return {
      success = false,
      error_code = 'UNEXPECTED_ERROR',
      message = 'Unexpected error occurred while unescaping string: ' .. tostring(result),
      suggestions = {
        'Check plugin installation and configuration',
        'Check Neovim logs for detailed information',
        'Restart Neovim and try again'
      }
    }
  end

  return result
end

-- Get current configuration
-- @return table Current configuration
function M.get_config()
  return vim.deepcopy(config)
end


-- Wrap current visual selection in quotes and escape content
-- @param quote_type string Quote type parameter ('single' or 'double')
-- @return table API response
function M.wrap_string(quote_type)
  local success, result = pcall(function()
    -- Check if current buffer is modifiable
    local current_bufnr = vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_get_option(current_bufnr, 'modifiable') then
      return {
        success = false,
        error_code = 'BUFFER_NOT_MODIFIABLE',
        message = 'Current buffer is not modifiable. Cannot wrap string in read-only buffer.',
        suggestions = {
          'Check if file is read-only',
          'Ensure you have file write permissions',
          'Try using :set modifiable command'
        }
      }
    end

    -- Detect current mode and get string information
    local mode = vim.fn.mode()
    local string_result

    if mode == 'v' or mode == 'V' or mode == '\22' then
      string_result = M._handle_visual_mode()
    else
      -- Try to fallback to last visual selection if possible, or attempt normal mode string detection
      -- For wrapping, we usually expect a selection. 
      -- But let's try handle_visual_mode anyway properly.
      -- If handle_visual_mode fails in normal mode (it checks mode), then we return error.
      -- Re-check handle_visual_mode: it explicitly checks mode.
      -- So we must be in visual mode OR we need to fake it or use marks.
      -- Since I cannot easily change handle_visual_mode right now without risk, 
      -- I will return error if not in visual mode, similar to escape_string.
       return {
        success = false,
        error_code = 'UNSUPPORTED_MODE',
        message = 'Please use visual mode to select text to wrap.',
        suggestions = {
          'Use v key to enter visual mode and select text'
        }
      }
    end

    if not string_result.success then
      return string_result
    end

    local string_info = string_result.data

    -- Validate string content
    if not string_info.content or string_info.content == '' then
      return {
        success = false,
        error_code = 'EMPTY_CONTENT',
        message = 'Empty content detected. No content to wrap.',
      }
    end

    -- Determine quote char
    local quote_char = "\""
    if quote_type == "single" then
      quote_char = "'"
    end
    
    -- Escape the CONTENT. 
    -- Note: string_info.content is the RAW selection.
    -- We want to escape it and wrap it.
    local content_to_escape = string_info.content
    local escaped_content = escape_handler.escape(content_to_escape, quote_char)
    local wrapped_content = quote_char .. escaped_content .. quote_char

    -- Replace content in buffer
    local start_row = string_info.start_pos[1] - 1
    local start_col = string_info.start_pos[2]
    local end_row = string_info.end_pos[1] - 1
    local end_col = string_info.end_pos[2]

    local replacement_lines = vim.split(wrapped_content, '\n', { plain = true })

    vim.api.nvim_buf_set_text(current_bufnr, start_row, start_col, end_row, end_col, replacement_lines)

    select_updated_range(start_row, start_col, replacement_lines, mode)

    return {
      success = true,
      message = 'String wrapped and escaped.',
      data = {
        wrapped_content = wrapped_content,
        original_length = #content_to_escape,
        new_length = #wrapped_content
      }
    }
  end)

  if not success then
    return {
      success = false,
      error_code = 'UNEXPECTED_ERROR',
      message = 'Unexpected error occurred while wrapping string: ' .. tostring(result)
    }
  end

  return result
end


-- Unwrap string: unescape content and remove surrounding quotes
-- @return table API response
function M.unwrap_string()
  local success, result = pcall(function()
    -- Check if current buffer is modifiable
    local current_bufnr = vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_get_option(current_bufnr, 'modifiable') then
      return {
        success = false,
        error_code = 'BUFFER_NOT_MODIFIABLE',
        message = 'Current buffer is not modifiable. Cannot unwrap string in read-only buffer.',
        suggestions = {
          'Check if file is read-only',
          'Ensure you have file write permissions',
          'Try using :set modifiable command'
        }
      }
    end

    -- Detect current mode and get string information
    local mode = vim.fn.mode()
    local string_result

    if mode == 'v' or mode == 'V' or mode == '\22' then
      string_result = M._handle_visual_mode()
    elseif mode == 'n' then
      string_result = M._handle_normal_mode()
    else
      return {
        success = false,
        error_code = 'UNSUPPORTED_MODE',
        message = 'Unsupported editor mode. Please use this feature in normal mode or visual mode.'
      }
    end

    if not string_result.success then
      return string_result
    end

    local string_info = string_result.data

    -- Validate string content
    if not string_info.inner_content then
       -- If inner_content is nil/empty, behaves like empty string
       -- But if content exists, let's process it.
       -- If empty string, unwrap -> empty.
    end

    -- Unescape the INNER content
    local unescaped_content = escape_handler.unescape(string_info.inner_content or "")

    -- Replace the content in the buffer
    -- For Unwrap, we replace the WHOLE range (start_pos to end_pos) with the inner content.
    -- This effectively removes the quotes (in Normal mode) or replaces selection (Visual mode).
    
    local start_row = string_info.start_pos[1] - 1
    local start_col = string_info.start_pos[2]
    local end_row = string_info.end_pos[1] - 1
    local end_col = string_info.end_pos[2]

    -- Split the unescaped content into lines for replacement
    local replacement_lines = vim.split(unescaped_content, '\n', { plain = true })

    -- Replace the text in the buffer
    vim.api.nvim_buf_set_text(current_bufnr, start_row, start_col, end_row, end_col, replacement_lines)


    select_updated_range(start_row, start_col, replacement_lines, mode)

    -- // print start and end position
    vim.notify('Start position: ' .. start_row .. ',' .. start_col .. '\nEnd position: ' .. end_row .. ',' .. end_col)

    return {
      success = true,
      message = 'String unwrapped successfully.',
      data = {
        original_length = #(string_info.content or ""),
        unwrapped_length = #unescaped_content
      }
    }
  end)

  if not success then
    return {
      success = false,
      error_code = 'UNEXPECTED_ERROR',
      message = 'Unexpected error occurred while unwrapping string: ' .. tostring(result)
    }
  end

  return result
end

return M

