-- octocode.nvim plugin entry point
-- This file is automatically loaded by Neovim

-- Prevent loading twice
if vim.g.loaded_octocode then
  return
end
vim.g.loaded_octocode = true

-- Check Neovim version compatibility
if vim.fn.has('nvim-0.8') == 0 then
  vim.api.nvim_err_writeln('octocode.nvim requires Neovim 0.8+')
  return
end

-- Auto-setup with default configuration if not already configured
if not vim.g.octocode_setup_done then
  require('octocode').setup()
  vim.g.octocode_setup_done = true
end