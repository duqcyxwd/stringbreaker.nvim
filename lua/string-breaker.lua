-- String Editor Plugin Main Module
-- Provides commands for editing escaped strings in Neovim

local M = {}

local core = require('string-breaker.core')

-- Plugin configuration
local config = {
  -- Default configuration options can be added here
}

-- Plugin setup function
function M.setup(opts)
  -- Merge user options with default config
  config = vim.tbl_deep_extend('force', config, opts or {})

  -- Setup StringBreaker with the same config
  core.setup(opts)

  -- Register enhanced commands
  vim.api.nvim_create_user_command('BreakString', core.break_string,
    { desc = 'Break string at cursor position or visual selection for editing', range = true })

  vim.api.nvim_create_user_command('PreviewString', core.preview,
    { desc = 'Preview unescaped string content at cursor position or visual selection', range = true })

  vim.api.nvim_create_user_command('BreakStringCancel', core.cancel,
    { desc = 'Cancel string editing without saving changes' })

  vim.api.nvim_create_user_command('SaveString', core.save, { desc = 'Save edited string back to original file' })
  
  vim.api.nvim_create_user_command('SyncString', core.sync, { desc = 'Synchronize string editor buffer with original file without closing' })

  vim.api.nvim_create_user_command('StringEscape', function(opts)
    local quote_type = opts.args and opts.args ~= '' and opts.args or nil
    core.escape_string(quote_type)
  end, { 
    desc = 'Escape selected string content with specified quote type (single/double)', 
    range = true, 
    nargs = '?' 
  })

  vim.api.nvim_create_user_command('StringUnescape', function(opts)
    local quote_type = opts.args and opts.args ~= '' and opts.args or nil
    core.unescape_string(quote_type)
  end, { 
    desc = 'Unescape selected string content', 
    range = true, 
    nargs = '?' 
  })
end

-- Export public functions
M.save = core.save
M.sync = core.sync
M.break_string = core.break_string
M.preview = core.preview
M.cancel = core.cancel
M.escape_string = core.escape_string
M.unescape_string = core.unescape_string

return M
