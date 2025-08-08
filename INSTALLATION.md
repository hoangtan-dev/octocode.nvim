# Installation Guide for octocode.nvim

## Method 1: Manual Installation (Quickest for Testing)

1. **Copy plugin to Neovim's runtime path:**
   ```bash
   # Create the plugin directory
   mkdir -p ~/.local/share/nvim/site/pack/local/start/octocode.nvim
   
   # Copy all plugin files
   cp -r . ~/.local/share/nvim/site/pack/local/start/octocode.nvim/
   
   # Or use the Makefile
   make install
   ```

2. **Restart Neovim** (important!)

3. **Test the plugin:**
   ```vim
   :Octocode
   ```

## Method 2: Add to Your Neovim Config

If you want to load it from the current directory without copying:

1. **Add to your init.lua:**
   ```lua
   -- Add current directory to runtime path
   vim.opt.runtimepath:append('/path/to/octocode.nvim')
   
   -- Setup the plugin
   require('octocode').setup()
   ```

2. **Or create a symlink:**
   ```bash
   ln -s /path/to/octocode.nvim ~/.local/share/nvim/site/pack/local/start/octocode.nvim
   ```

## Method 3: Plugin Manager (Recommended for Production)

### Using lazy.nvim
```lua
{
  dir = "/path/to/octocode.nvim", -- Use local path
  name = "octocode.nvim",
  config = function()
    require("octocode").setup()
  end,
}
```

### Using packer.nvim
```lua
use {
  "/path/to/octocode.nvim", -- Use local path
  config = function()
    require("octocode").setup()
  end,
}
```

## Method 4: Development Setup

For active development:

1. **Create development symlink:**
   ```bash
   # From the octocode.nvim directory
   ln -sf $(pwd) ~/.local/share/nvim/site/pack/local/start/octocode.nvim
   ```

2. **Add to your init.lua for auto-reload:**
   ```lua
   -- Auto-reload plugin during development
   vim.keymap.set('n', '<leader>rr', function()
     -- Clear module cache
     for name, _ in pairs(package.loaded) do
       if name:match('^octocode') then
         package.loaded[name] = nil
       end
     end
     -- Reload plugin
     require('octocode').setup()
     print('octocode.nvim reloaded!')
   end, { desc = 'Reload octocode plugin' })
   ```

## Troubleshooting

### Error: "module 'octocode' not found"

1. **Check if plugin is in the right location:**
   ```bash
   ls ~/.local/share/nvim/site/pack/local/start/octocode.nvim/lua/octocode/
   ```
   Should show: `init.lua`, `ui.lua`, `search.lua`

2. **Check Neovim's runtime path:**
   ```vim
   :echo &runtimepath
   ```
   Should include the plugin directory.

3. **Manually add to runtime path:**
   ```vim
   :set runtimepath+=~/.local/share/nvim/site/pack/local/start/octocode.nvim
   :lua require('octocode').setup()
   ```

### Error: "attempt to call field 'setup' (a nil value)"

This means the module loaded but `setup` function is missing. Check:
```vim
:lua print(vim.inspect(require('octocode')))
```

### Plugin loads but :Octocode command not found

The plugin might not be auto-loading. Try:
```vim
:lua require('octocode').setup()
:Octocode
```

## Quick Test Script

Create a test file to verify installation:

```lua
-- test_octocode.lua
local function test_plugin()
  local ok, octocode = pcall(require, 'octocode')
  if not ok then
    print("❌ Plugin not found: " .. octocode)
    return false
  end
  
  print("✅ Plugin loaded successfully")
  
  -- Test setup
  local setup_ok, err = pcall(octocode.setup)
  if not setup_ok then
    print("❌ Setup failed: " .. err)
    return false
  end
  
  print("✅ Setup completed")
  
  -- Test command
  local commands = vim.api.nvim_get_commands({})
  if commands.Octocode then
    print("✅ :Octocode command available")
  else
    print("❌ :Octocode command not found")
  end
  
  return true
end

test_plugin()
```

Run with: `:luafile test_octocode.lua`

## Current Directory Quick Setup

If you're in the octocode.nvim directory right now:

```bash
# Quick install
make install

# Restart Neovim
nvim

# Test
:Octocode
```

Or manually:
```bash
# Copy to Neovim
cp -r . ~/.local/share/nvim/site/pack/local/start/octocode.nvim/

# Start Neovim
nvim

# The plugin should auto-load, test with:
:Octocode
```