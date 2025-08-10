# octocode.nvim

A simple yet powerful Neovim plugin that provides semantic search capabilities by integrating with the octocode CLI tool.

[![asciicast](https://asciinema.org/a/732758.svg)](https://asciinema.org/a/732758)

![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg)
![Lua](https://img.shields.io/badge/Made%20with-Lua-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## ✨ Features

- 🔍 **Semantic Search**: Powerful search across your codebase using octocode CLI
- 🎯 **Multiple Modes**: Search All, Code, Docs, or Text content specifically  
- 🪟 **Floating Window UI**: Clean, modern interface with floating windows
- ⚡ **Async Execution**: Non-blocking search with job control
- 🎨 **Syntax Highlighting**: Beautiful results display with proper highlighting
- 🔗 **Clickable Results**: Direct navigation to files and line numbers
- ⌨️ **Vim-like Keybindings**: Intuitive navigation and mode switching

## 📋 Requirements

- Neovim 0.8+
- `octocode` CLI tool installed and available in PATH

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/octocode.nvim",
  config = function()
    require("octocode").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "your-username/octocode.nvim",
  config = function()
    require("octocode").setup()
  end,
}
```

## ⚙️ Configuration

Default configuration:

```lua
require("octocode").setup({
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
})
```

## 🚀 Usage

### Basic Workflow

1. **Open Search**: Press `<leader>os` or run `:Octocode`
2. **Enter Query**: Type your search query
3. **Select Mode**: Use keys to switch modes:
   - `a` - **All** (search everything)
   - `c` - **Code** (search only code blocks)
   - `d` - **Docs** (search only documentation)
   - `t` - **Text** (search only text content)
4. **Execute**: Press `<Enter>` to search
5. **Navigate**: Use arrow keys to browse results
6. **Open File**: Press `<Enter>` on a result to open the file
7. **Close**: Press `<Esc>` to close the interface

### Search Modes

- **All**: Comprehensive search across all content types
- **Code**: Focuses on code blocks, functions, and symbols
- **Docs**: Searches documentation and markdown files
- **Text**: Searches plain text content

### Example Queries

```
training pipeline for lstm
user authentication flow
database connection handling
error handling patterns
```

## ⌨️ Keymaps

### Global
- `<leader>os` - Toggle search interface

### Search Interface
- `<Enter>` - Execute search (input) / Open file (results)
- `<Esc>` - Close interface
- `a` - Switch to All mode
- `c` - Switch to Code mode
- `d` - Switch to Docs mode
- `t` - Switch to Text mode

## 🎨 Screenshots

*Search Interface*
```
┌─ Search Query [All] ─────────────────────────────────┐
│ training pipeline for lstm                           │
│ -- Modes: (a)ll, (c)ode, (d)ocs, (t)ext | Enter to │
└──────────────────────────────────────────────────────┘
```

*Results Display*
```
┌─ Octocode Results ───────────────────────────────────┐
│ === Octocode Search Results ===                      │
│                                                      │
│ 📄 Code Results:                                     │
│                                                      │
│   1. src/model/lstm_simple_test.rs:3-12 (0.384)     │
│      Symbols: test_lstm_train_predict_shape          │
│      #[tokio::test]                                  │
│      async fn test_lstm_train_predict_shape() {      │
│      let config = LSTMConfig::default();             │
│      ...                                             │
│                                                      │
│ Press <Enter> on a result to open the file          │
│ Press <Esc> to close                                 │
└──────────────────────────────────────────────────────┘
```

## 🔧 API

```lua
-- Setup plugin
require("octocode").setup(opts)

-- Toggle interface
require("octocode.ui").toggle()

-- Open/close interface
require("octocode.ui").open()
require("octocode.ui").close()

-- Execute search programmatically
require("octocode.search").execute(query, mode, results_buf)
```

## 🐛 Troubleshooting

### Command not found
Ensure `octocode` is installed and available in your PATH:
```bash
which octocode
octocode --version
```

### No results
- Check if you're in a valid project directory
- Verify the query format
- Try different search modes

### Plugin not loading
- Ensure Neovim 0.8+
- Check for plugin conflicts
- Verify installation path

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- Built for integration with the octocode CLI tool
- Inspired by modern Neovim plugin best practices
- Uses Neovim's built-in floating window and job control APIs
