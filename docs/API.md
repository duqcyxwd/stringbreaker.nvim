# StringBreaker API Reference

This document provides detailed description of the StringBreaker plugin Lua API interface.

## Module Import

```lua
local stringBreaker = require('string-breaker')
```

## Command to API Mapping

| Command | API Function | Description |
|---------|--------------|-------------|
| `:BreakString` | `stringBreaker.break_string()` | Start editing string |
| `:PreviewString` | `stringBreaker.preview()` | Preview string content |
| `:SaveString` | `stringBreaker.save()` | Save edited string |
| `:BreakStringCancel` | `stringBreaker.cancel()` | Cancel editing without saving |

## Core API Functions

### `stringBreaker.break_string()`

Start editing a string or selected text.

**Return Value**: `table` - API response object

**Behavior**:
- **Normal Mode**: Uses Tree-sitter to detect string at cursor position
- **Visual Mode**: Edit selected text
- Creates temporary editing buffer with unescaped string content
- Sets buffer type to `stringBreaker`

**Example**:
```lua
local result = stringBreaker.break_string()

if result.success then
  print("Editing buffer created: " .. result.data.edit_buffer)
  print("Source type: " .. result.data.source_type)
  print("Content length: " .. result.data.content_length)
else
  print("Error: " .. result.message)
  print("Error code: " .. result.error_code)
  
  if result.suggestions then
    for _, suggestion in ipairs(result.suggestions) do
      print("Suggestion: " .. suggestion)
    end
  end
end
```

**Success Response Data**:
```lua
{
  success = true,
  message = "String opened for editing...",
  data = {
    edit_buffer = 42,           -- Buffer number of editing buffer
    source_type = "treesitter", -- "treesitter" or "visual"
    content_length = 123        -- Length of unescaped content
  }
}
```

**Possible Error Codes**:
- `TREESITTER_UNAVAILABLE`: Tree-sitter unavailable in normal mode
- `NO_STRING_FOUND`: No string found at cursor position
- `INVALID_SELECTION`: Invalid visual selection
- `BUFFER_NOT_MODIFIABLE`: Current buffer is not modifiable
- `UNSUPPORTED_MODE`: Unsupported editor mode
- `EMPTY_CONTENT`: Empty string content
- `USER_CANCELLED`: User cancelled operation
- `BUFFER_CREATION_FAILED`: Failed to create editing buffer
- `UNEXPECTED_ERROR`: Unexpected system error

---

### `stringBreaker.preview()`

Preview unescaped string content without creating an editing buffer.

**Return Value**: `table` - API response object

**Behavior**:
- Detect and get string content (normal or visual mode)
- Display unescaped content via notification, echo, or floating window
- Does not modify any files or create editing buffers

**Example**:
```lua
local result = stringBreaker.preview()
if result.success then
  print("Preview content length: " .. result.data.length)
  print("Source type: " .. result.data.source_type)
  print("Content: " .. result.data.content:sub(1, 50) .. "...")
else
  print("Preview failed: " .. result.message)
  print("Error code: " .. result.error_code)
end
```

**Success Response Data**:
```lua
{
  success = true,
  message = "String preview displayed.",
  data = {
    content = "Hello\nWorld",    -- Unescaped content
    source_type = "treesitter",  -- "treesitter" or "visual"
    length = 11                  -- Content length
  }
}
```

**Preview Display Rules**:
- Content > 100 characters and `config.preview.use_float = true`: Floating window
- Content ≤ 200 characters: Notification message
- Other cases: Echo area display

**Floating Window Controls**:
- `q` or `Esc`: Close preview window
- Auto-close after 5 seconds

---

### `stringBreaker.save()`

Save edited string back to original file. Can only be called in `stringBreaker` buffer type.

**Return Value**: `table` - API response object (implicitly, via notifications)

**Behavior**:
- Validates current buffer is `stringBreaker` type
- Gets editing buffer content and escapes it appropriately
- Replaces original string content in source file
- Closes editing buffer and switches back to original buffer
- Validates original buffer and positions are still valid

**Example**:
```lua
-- Must be called in editing buffer (filetype = 'stringBreaker')
local result = stringBreaker.save()
if result and result.success then
  print("String saved successfully")
else
  print("Save operation failed")
end
```

**Requirements**:
- Must be called in buffer with `filetype = 'stringBreaker'`
- Original buffer must still exist and be modifiable
- Original string position must still be valid

**Error Handling**:
- Displays notifications for various error conditions
- Gracefully handles buffer invalidation and file modification
- Provides specific error messages for different failure modes

---

### `stringBreaker.cancel()`

Cancel editing and close editing buffer without saving changes.

**Return Value**: `table` - API response object

**Behavior**:
- Verifies currently in editing buffer
- Closes editing buffer without saving
- Switches back to original buffer
- Does not modify original file

**Example**:
```lua
-- Can be called in editing buffer or anywhere
local result = stringBreaker.cancel()
if result.success then
  print("Editing cancelled: " .. result.message)
else
  print("Cancel failed: " .. result.message)
end
```

**Success Response**:
```lua
{
  success = true,
  message = "Editing cancelled. Original file unchanged."
}
```

**Error Response**:
```lua
{
  success = false,
  error_code = "NOT_IN_EDIT_BUFFER",
  message = "cancel() can only be used in string editing buffer.",
  suggestions = {
    "Ensure this function is called in string editing buffer",
    "Use break_string() function to start editing string"
  }
}
```

---

## Configuration API

### `stringBreaker.setup(opts)`

Configure StringBreaker plugin.

**Parameters**:
- `opts` (`table`, optional): Configuration options

**Configuration Options**:
```lua
{
  preview = {
    max_length = 1000,    -- Maximum preview content length
    use_float = true,     -- Whether to use floating window
    width = 80,           -- Floating window width
    height = 20           -- Floating window height
  }
}
```

**Example**:
```lua
stringBreaker.setup({
  preview = {
    max_length = 2000,
    width = 100,
    height = 30,
    use_float = false  -- Use echo/notification instead
  }
})
```

---

### `stringBreaker.get_config()`

Get current configuration.

**Return Value**: `table` - Deep copy of current configuration

**Example**:
```lua
local config = stringBreaker.get_config()
print("Preview max length: " .. config.preview.max_length)
print("Use floating window: " .. tostring(config.preview.use_float))
```

---

## Internal API Functions

These functions are primarily for internal use, but can also be called in advanced scenarios.


---

### `stringBreaker._handle_normal_mode()`

Handle string detection in normal mode using Tree-sitter.

**Return Value**: `table` - Response containing string information or error information

**Example**:
```lua
local result = stringBreaker._handle_normal_mode()
if result.success then
  local string_info = result.data
  print("Found string: " .. string_info.inner_content)
  print("Quote type: " .. string_info.quote_type)
  print("Position: " .. vim.inspect(string_info.start_pos))
end
```

---

### `stringBreaker._handle_visual_mode()`

Handle text selection in visual mode.

**Return Value**: `table` - Response containing string information or error information

**Example**:
```lua
-- Must be called while in visual mode
local result = stringBreaker._handle_visual_mode()
if result.success then
  local string_info = result.data
  print("Selected content: " .. string_info.inner_content)
  print("Source type: " .. string_info.source_type)
end
```

---

### `stringBreaker._show_float_preview(content, source_type)`

Show floating window preview for content.

**Parameters**:
- `content` (`string`): Content to display in preview
- `source_type` (`string`): Content source type for window title

**Example**:
```lua
stringBreaker._show_float_preview("Hello\nWorld\nPreview", "manual")
-- Creates floating window with content and "manual" source type
```

---

## API Response Format

All public API functions return standardized response objects:

### Success Response
```lua
{
  success = true,
  message = "Operation completed successfully",
  data = {
    -- Function-specific data
    content = "String content",
    source_type = "treesitter" | "visual",
    length = 123,
    edit_buffer = 42  -- For break_string() only
  }
}
```

### Error Response
```lua
{
  success = false,
  error_code = "ERROR_CODE",
  message = "User-friendly error message",
  suggestions = {
    "Suggested solution 1",
    "Suggested solution 2"
  }
}
```

---

## Error Code Reference

| Error Code | Description | Common Causes | Solutions |
|------------|-------------|---------------|-----------|
| `TREESITTER_UNAVAILABLE` | Tree-sitter not available | nvim-treesitter not installed, parser missing | Install nvim-treesitter, use visual mode |
| `NO_STRING_FOUND` | No string at cursor | Cursor not inside string | Move cursor inside quotes, use visual mode |
| `INVALID_SELECTION` | Invalid visual selection | Empty selection, invalid range | Re-select text, ensure non-empty content |
| `BUFFER_NOT_MODIFIABLE` | Buffer is read-only | File permissions, buffer settings | Check permissions, `:set modifiable` |
| `UNSUPPORTED_MODE` | Wrong editor mode | Called in insert mode | Use in normal or visual mode |
| `EMPTY_CONTENT` | No content to edit | Empty string, empty selection | Select content with actual text |
| `USER_CANCELLED` | User cancelled operation | User chose cancel in dialog | User choice, no action needed |
| `BUFFER_CREATION_FAILED` | Could not create buffer | Memory issues, system errors | Check memory, restart Neovim |
| `NOT_IN_EDIT_BUFFER` | Wrong buffer type | Called save/cancel outside edit buffer | Ensure in `stringBreaker` buffer |
| `CANCEL_FAILED` | Cancel operation failed | System error during cleanup | Force close buffer manually |
| `UNEXPECTED_ERROR` | Unexpected system error | Various system issues | Check logs, restart Neovim |

---

## Usage Patterns

### 1. Basic Edit Workflow
```lua
local stringBreaker = require('string-breaker')

-- Start editing
local result = stringBreaker.break_string()
if not result.success then
  vim.notify("Cannot start editing: " .. result.message, vim.log.levels.ERROR)
  return
end

-- User edits in editing buffer...
-- Save is typically done via :SaveString command or save() API
```

### 2. Preview Then Edit
```lua
local stringBreaker = require('string-breaker')

-- Preview content first
local preview_result = stringBreaker.preview()
if preview_result.success then
  print("Preview length: " .. preview_result.data.length)
  
  if preview_result.data.length > 200 then
    local choice = vim.fn.confirm('String is long, continue?', '&Yes\n&No', 1)
    if choice == 1 then
      stringBreaker.break_string()
    end
  else
    stringBreaker.break_string()
  end
else
  vim.notify("Preview failed: " .. preview_result.message, vim.log.levels.WARN)
end
```

### 3. Comprehensive Error Handling
```lua
local stringBreaker = require('string-breaker')

local function safe_string_edit()
  local result = stringBreaker.break_string()
  
  if not result.success then
    -- Display main error
    vim.notify(result.message, vim.log.levels.ERROR)
    
    -- Show specific suggestions
    if result.suggestions and #result.suggestions > 0 then
      for i, suggestion in ipairs(result.suggestions) do
        vim.notify(i .. ". " .. suggestion, vim.log.levels.INFO)
      end
    end
    
    -- Handle specific error codes
    if result.error_code == 'TREESITTER_UNAVAILABLE' then
      vim.notify('Try visual mode: select text then run command', vim.log.levels.INFO)
    elseif result.error_code == 'NO_STRING_FOUND' then
      vim.notify('Place cursor inside quotes or use visual selection', vim.log.levels.INFO)
    end
    
    return false
  end
  
  vim.notify('Editing started: ' .. result.message, vim.log.levels.INFO)
  return true
end
```

### 4. Mode-Aware Editing
```lua
local stringBreaker = require('string-breaker')

local function smart_edit()
  local mode = vim.fn.mode()
  
  if mode == 'v' or mode == 'V' or mode == '\22' then
    -- Visual mode: edit selection directly
    vim.notify('Editing visual selection...', vim.log.levels.INFO)
    return stringBreaker.break_string()
  elseif mode == 'n' then
    -- Normal mode: try string detection
    vim.notify('Detecting string at cursor...', vim.log.levels.INFO)
    return stringBreaker.break_string()
  else
    vim.notify('Unsupported mode: ' .. mode, vim.log.levels.WARN)
    return { success = false, message = 'Use normal or visual mode' }
  end
end
```

### 5. Custom Configuration
```lua
local stringBreaker = require('string-breaker')

-- Dynamic configuration based on content
local function setup_for_content_type(content_type)
  if content_type == 'json' then
    stringBreaker.setup({
      preview = { width = 120, height = 40, use_float = true }
    })
  elseif content_type == 'sql' then
    stringBreaker.setup({
      preview = { width = 150, height = 20, use_float = true }
    })
  else
    stringBreaker.setup({
      preview = { width = 80, height = 20, use_float = true }
    })
  end
end

-- Usage
setup_for_content_type('json')
stringBreaker.break_string()
```

---

## Integration Examples

### Telescope Integration
```lua
local function telescope_string_picker()
  local stringBreaker = require('string-breaker')
  
  -- Get all strings in buffer (pseudo-code)
  local strings = find_all_strings_in_buffer()
  
  require('telescope.pickers').new({}, {
    prompt_title = 'Select String to Edit',
    finder = require('telescope.finders').new_table({
      results = strings,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.content:sub(1, 50) .. '...',
          ordinal = entry.content,
        }
      end,
    }),
    actions = {
      ['<CR>'] = function(prompt_bufnr)
        local selection = require('telescope.actions.state').get_selected_entry()
        require('telescope.actions').close(prompt_bufnr)
        
        -- Move to string position and edit
        vim.api.nvim_win_set_cursor(0, selection.value.position)
        stringBreaker.break_string()
      end,
    },
  }):find()
end
```

### Autocommand Integration  
```lua
-- Auto-preview strings when cursor moves
vim.api.nvim_create_autocmd('CursorMoved', {
  pattern = '*.lua',
  callback = function()
    local stringBreaker = require('string-breaker')
    
    -- Quick preview without notification
    local result = stringBreaker.preview()
    if result.success and result.data.length > 100 then
      -- Show subtle indicator for long strings
      vim.notify('Long string available for editing', vim.log.levels.INFO)
    end
  end
})
```