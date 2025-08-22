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
  -- Merge configuration
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Create user commands
  vim.api.nvim_create_user_command("Octocode", function()
    require("octocode.ui").toggle()
  end, { desc = "Toggle Octocode search panel" })
  
  -- Set up default keybinding
  vim.keymap.set("n", M.config.keymaps.toggle, function()
    require("octocode.ui").toggle()
  end, { desc = "Toggle Octocode search", silent = true })
  
  -- Start watch process
  require("octocode.watch").setup()

  -- Toggle indexing with keybinding
  vim.keymap.set("n", "<leader>oi", function()
    require("octocode.watch").toggle()
  end, { desc = "Toggle Octocode indexing", silent = true })
end

return M
