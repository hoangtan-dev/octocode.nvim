-- Minimal init.lua for testing octocode.nvim

-- Add current directory to package path
local current_dir = vim.fn.getcwd()
package.path = current_dir .. "/lua/?.lua;" .. package.path

-- Set up basic Neovim configuration for testing
vim.opt.runtimepath:append(current_dir)

-- Load the plugin
require("octocode").setup({
  -- Test configuration
  default_mode = "All",
  window = {
    width = 0.8,
    height = 0.6,
    border = "single",
  },
  keymaps = {
    toggle = "<leader>os",
  },
  command = "echo", -- Use echo for testing instead of octocode
})

-- Helper function to test plugin loading
function _G.test_plugin_loaded()
  local ok, octocode = pcall(require, "octocode")
  if ok then
    print("✓ Plugin loaded successfully")
    return true
  else
    print("✗ Plugin failed to load: " .. tostring(octocode))
    return false
  end
end

-- Helper function to test UI
function _G.test_ui()
  local ok, ui = pcall(require, "octocode.ui")
  if ok then
    print("✓ UI module loaded successfully")
    return true
  else
    print("✗ UI module failed to load: " .. tostring(ui))
    return false
  end
end

-- Helper function to test search
function _G.test_search()
  local ok, search = pcall(require, "octocode.search")
  if ok then
    print("✓ Search module loaded successfully")
    return true
  else
    print("✗ Search module failed to load: " .. tostring(search))
    return false
  end
end

print("Minimal test environment loaded")