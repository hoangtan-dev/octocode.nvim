-- Test script to verify real splits work
-- Run with: nvim --clean -c "luafile test_splits.lua"

print("Testing real vim splits...")

-- Test 1: Create vertical split
vim.cmd("vsplit")
print("✅ Created vertical split")

-- Test 2: Resize to half
local half_width = math.floor(vim.o.columns / 2)
vim.cmd("vertical resize " .. half_width)
print("✅ Resized to half width: " .. half_width)

-- Test 3: Create horizontal split
vim.cmd("split")
print("✅ Created horizontal split")

-- Test 4: Resize top window
vim.cmd("resize 3")
print("✅ Resized top window to 3 lines")

-- Test 5: List all windows
local windows = vim.api.nvim_list_wins()
print("✅ Total windows: " .. #windows)

for i, win in ipairs(windows) do
  local config = vim.api.nvim_win_get_config(win)
  if config.relative == "" then
    print("  Window " .. i .. ": NORMAL SPLIT")
  else
    print("  Window " .. i .. ": FLOATING")
  end
end

print("\nIf all windows show 'NORMAL SPLIT', then splits are working correctly!")
print("Press any key to continue...")
vim.fn.getchar()