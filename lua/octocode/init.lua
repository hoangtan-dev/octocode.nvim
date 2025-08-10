-- octocode.nvim - Simple yet powerful semantic search plugin
-- Main module entry point

local M = {}

-- Plugin configuration
M.config = {
  -- Default search mode
  default_mode = "All",
  -- Window configuration
  window = {
    width = 0.8,
    height = 0.6,
    border = "rounded",
  },
  -- Keybindings
  keymaps = {
    toggle = "<leader>os",
    select = "<CR>",
    close = "<Esc>",
    mode_all = "a",
    mode_code = "c", 
    mode_docs = "d",
    mode_text = "t",
  },
  -- CLI command
  command = "octocode",
  -- Silent mode - prevents blocking notifications
  silent = false,
}

-- Setup function for user configuration
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Create user command
  vim.api.nvim_create_user_command("Octocode", function()
    require("octocode.ui").toggle()
  end, { desc = "Toggle Octocode search panel" })
  
  -- Set up default keybinding
  vim.keymap.set("n", M.config.keymaps.toggle, function()
    require("octocode.ui").toggle()
  end, { desc = "Toggle Octocode search", silent = true })
end

return M