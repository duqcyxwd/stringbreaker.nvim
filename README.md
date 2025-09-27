# StringBreaker - Neovim Escaped Strings Editor Plugin

A powerful Neovim plugin that makes it easy to **edit escaped strings** in code. StringBreaker provides intuitive commands and a flexible API, supporting both normal mode (using Tree-sitter) and visual mode (no dependencies required).

![StringBreaker Demo](assets/StringBreaker.gif)

> **📹 Demo Recording**: [View demo on asciinema](https://asciinema.org/a/N3UvVLXNpfxz0pC8TLrVXt1SL) | [Download GIF](assets/StringBreaker.gif)

## Features

- 🎯 **Smart String Detection**: Automatically detect strings at cursor position using Tree-sitter
- 👁️ **Visual Mode Support**: Select any text for editing, no Tree-sitter required
- 🔍 **Preview Functionality**: Quick preview of unescaped string content
- 🔧 **String Escape/Unescape**: Direct commands to escape and unescape string content in-place
- 💾 **Native Vim Integration**: Use familiar `:w`, `:wq` commands alongside plugin commands
- 🔄 **Flexible Sync Options**: Sync changes with or without closing the editor buffer
- 🛠️ **Unified API**: Clean Lua API for scripts and plugin integration
- 🔄 **Enhanced Buffer Management**: Optimized buffer handling and memory usage
- ⚡ **Multi-mode Support**: Works in normal mode and visual mode seamlessly

## Requirements

- Neovim 0.7+
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (optional, for normal mode string detection)
- Tree-sitter parsers for languages you want to edit (optional)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "duqcyxwd/stringbreaker.nvim",
  dependencies = { 
    "nvim-treesitter/nvim-treesitter" 
  },
  config = function()
    require("string-breaker").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "duqcyxwd/stringbreaker.nvim",
  requires = { 
    "nvim-treesitter/nvim-treesitter" 
  },
  config = function()
    require("string-breaker").setup()
  end,
}
```

## Quick Start

### Basic Workflow

1. **Position your cursor** inside any string in your code, or select text in visual mode
2. **Run `:BreakString`** to open the string/text in an editing buffer
3. **Edit the content** in the temporary buffer (escape sequences are automatically unescaped)
4. **Save changes** using either:
   - `:SaveString` - Save and close the editor buffer
   - `:wq` or `:w` - Standard Vim save commands (automatically syncs with original file)
   - `:SyncString` - Sync changes without closing the buffer
5. **Or cancel editing** with `:BreakStringCancel` or simply close the buffer without saving

### Commands

#### String Editing Commands
- `:BreakString` - Extract and edit the string at cursor position or visual selection
- `:PreviewString` - Preview unescaped string content without opening editor
- `:SaveString` - Save edited content back to original file and close buffer
- `:SyncString` - Synchronize changes with original file without closing buffer
- `:BreakStringCancel` - Cancel editing without saving changes

#### String Manipulation Commands
- `:StringEscape [single|double]` - Escape selected string content or string at cursor
- `:StringUnescape` - Unescape selected string content or string at cursor

**Standard Vim commands also work:**
- `:w` or `:write` - Save changes (automatically syncs with original file)
- `:wq` - Save changes and close buffer
- `:q!` - Close buffer without saving changes

### Examples

#### String Editing Example

Given this JavaScript code:
```javascript
const message = "Hello\\nWorld\\t\"Quote\"";
```

1. Place cursor inside the string or select it
2. Run `:BreakString`
3. Edit in the temporary buffer:
```
Hello
World	"Quote"
```
4. Save changes using `:SaveString`, `:wq`, or `:w` to update the original file

#### String Escape/Unescape Examples

**Escaping strings:**
```javascript
// Original text (select in visual mode or place cursor inside)
Hello
World	"Quote"

// Run :StringEscape double
// Result:
"Hello\\nWorld\\t\"Quote\""
```

**Unescaping strings:**
```javascript
// Original escaped string (select or place cursor inside)
"Hello\\nWorld\\t\"Quote\""

// Run :StringUnescape
// Result:
Hello
World	"Quote"
```

**Quote type selection:**
- `:StringEscape single` - Use single quotes and escape single quotes in content
- `:StringEscape double` - Use double quotes and escape double quotes in content (default)

## Usage Modes

### Normal Mode (Tree-sitter)
- **How**: Place cursor inside any string literal
- **Requirements**: nvim-treesitter with appropriate language parser
- **Benefits**: Automatic string detection and boundary identification

### Visual Mode (No dependencies)
- **How**: Select any text, then run `:BreakString`
- **Requirements**: None
- **Benefits**: Works with any text, even partial strings or complex content

## Supported Languages

The plugin works with any programming language that has Tree-sitter support for normal mode, including:

- JavaScript/TypeScript
- Python  
- Lua
- Java
- And many more...

Visual mode works with any file type.

## Configuration

### Basic Setup

```lua
require("string-breaker").setup({
  preview = {
    max_length = 1000,    -- Maximum preview content length
    use_float = true,     -- Use floating window for preview
    width = 100,           -- Floating window width  
    height = 4           -- Floating window height
  }
})
```

### Suggested Keybindings

```lua
local stringBreaker = require('string-breaker')

--- keybindings example
vim.keymap.set({'n', 'v'}, '<space>fes', stringBreaker.break_string, { desc = 'Break string for editing' })
vim.keymap.set({'n', 'v'}, '<space>fep', stringBreaker.preview, { desc = 'Preview string content' })
vim.keymap.set('n', '<space>fec', stringBreaker.cancel, { desc = 'Cancel string editing' })


-- Auto-keybindings in string editor buffers
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'stringBreaker',
  callback = function()
    local opts = { buffer = true, silent = true }
    vim.keymap.set('n', '<space>fs', stringBreaker.save, opts)
    vim.keymap.set('n', '<space>qq', stringBreaker.cancel, opts)
  end
})

```

## Lua API

StringBreaker provides a clean Lua API for advanced usage:

```lua
local stringBreaker = require('string-breaker')

-- Start editing string/selection
local result = stringBreaker.break_string()
if result.success then
  print("Editing started: " .. result.message)
else
  print("Error: " .. result.message)
end

-- Preview string content
local result = stringBreaker.preview()
if result.success then
  print("Content length: " .. result.data.length)
end

-- Escape string content (in normal mode: cursor position, visual mode: selection)
local result = stringBreaker.escape_string("double")  -- or "single"
if result.success then
  print("Escaped with " .. result.data.quote_type .. " quotes")
  print("Original length: " .. result.data.original_length)
  print("Escaped length: " .. result.data.escaped_length)
end

-- Unescape string content
local result = stringBreaker.unescape_string()
if result.success then
  print("Unescaped successfully")
  print("Original length: " .. result.data.original_length)
  print("Unescaped length: " .. result.data.unescaped_length)
end

-- Synchronize changes with original file (in editing buffer)
local result = stringBreaker.sync()
if result.success then
  print("Synchronized:", result.data.changed)
  print("Content length:", result.data.content_length)
end

-- Save changes and close buffer (in editing buffer)
stringBreaker.save()

-- Cancel editing (in editing buffer)
stringBreaker.cancel()
```

All API functions return standardized response objects with `success`, `message`, `error_code`, and `data` fields.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see LICENSE file for details.