-- Test runner for octocode.nvim

local M = {}

-- Test results
local results = {
  passed = 0,
  failed = 0,
  tests = {}
}

-- Test helper functions
local function assert_true(condition, message)
  if condition then
    results.passed = results.passed + 1
    table.insert(results.tests, "✓ " .. message)
    return true
  else
    results.failed = results.failed + 1
    table.insert(results.tests, "✗ " .. message)
    return false
  end
end

local function assert_not_nil(value, message)
  return assert_true(value ~= nil, message)
end

-- Test plugin loading
local function test_plugin_loading()
  print("\n=== Testing Plugin Loading ===")
  
  local ok, octocode = pcall(require, "octocode")
  assert_true(ok, "Plugin module loads without error")
  assert_not_nil(octocode.setup, "setup function exists")
  assert_not_nil(octocode.config, "config table exists")
  
  local ok_ui, ui = pcall(require, "octocode.ui")
  assert_true(ok_ui, "UI module loads without error")
  assert_not_nil(ui.toggle, "UI toggle function exists")
  assert_not_nil(ui.open, "UI open function exists")
  assert_not_nil(ui.close, "UI close function exists")
  
  local ok_search, search = pcall(require, "octocode.search")
  assert_true(ok_search, "Search module loads without error")
  assert_not_nil(search.execute, "Search execute function exists")
end

-- Test configuration
local function test_configuration()
  print("\n=== Testing Configuration ===")
  
  local octocode = require("octocode")
  
  -- Test default config
  assert_not_nil(octocode.config.default_mode, "Default mode is set")
  assert_not_nil(octocode.config.window, "Window config exists")
  assert_not_nil(octocode.config.keymaps, "Keymaps config exists")
  assert_not_nil(octocode.config.command, "Command config exists")
  
  -- Test custom config
  local custom_config = {
    default_mode = "Code",
    window = { width = 0.9 }
  }
  
  octocode.setup(custom_config)
  assert_true(octocode.config.default_mode == "Code", "Custom config applied")
  assert_true(octocode.config.window.width == 0.9, "Custom window config applied")
end

-- Test commands
local function test_commands()
  print("\n=== Testing Commands ===")
  
  -- Check if user command is created
  local commands = vim.api.nvim_get_commands({})
  assert_not_nil(commands.Octocode, "Octocode command is created")
end

-- Test API functions
local function test_api()
  print("\n=== Testing API ===")
  
  local ui = require("octocode.ui")
  
  -- Test that functions don't error when called
  local ok_toggle = pcall(ui.toggle)
  assert_true(ok_toggle, "UI toggle doesn't error")
  
  -- Close if opened
  pcall(ui.close)
end

-- Run all tests
function M.run_all()
  print("Running octocode.nvim tests...")
  
  test_plugin_loading()
  test_configuration()
  test_commands()
  test_api()
  
  -- Print results
  print("\n=== Test Results ===")
  for _, test in ipairs(results.tests) do
    print(test)
  end
  
  print(string.format("\nPassed: %d, Failed: %d", results.passed, results.failed))
  
  if results.failed == 0 then
    print("✓ All tests passed!")
    return true
  else
    print("✗ Some tests failed!")
    return false
  end
end

return M