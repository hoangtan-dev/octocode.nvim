# octocode.nvim

🚀 **Intelligent code search for Neovim** - Semantic search that understands your code, powered by the octocode CLI.

[![asciicast](https://asciinema.org/a/732758.svg)](https://asciinema.org/a/732758)

![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg)
![Lua](https://img.shields.io/badge/Made%20with-Lua-blue.svg)
![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)

## ✨ Features

- 🔍 **Semantic Search**: Natural language queries that understand code context
- 🎯 **Smart Modes**: Search All, Code only, Documentation, or Text content
- 🔄 **Auto-indexing**: Automatic background indexing with file watching
- ⚡ **Instant Results**: Fast, async search with real-time updates
- 🎨 **Beautiful UI**: Clean split-window interface with syntax highlighting
- 🔗 **Quick Navigation**: Jump directly to code with clickable results
- ⌨️ **Vim-native**: Intuitive keybindings that feel right at home

## 📋 Requirements

- Neovim 0.8+ (0.10+ recommended for best performance)
- [octocode](https://github.com/Muvon/octocode) CLI tool installed and in PATH

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "Muvon/octocode.nvim",
  config = function()
    require("octocode").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "Muvon/octocode.nvim",
  config = function()
    require("octocode").setup()
  end,
}
```

## ⚙️ Configuration

**Zero configuration needed!** The plugin works out of the box with sensible defaults.

### Optional Customization

```lua
require("octocode").setup({
  -- Change the toggle keybinding (default: <leader>os)
  keymaps = {
    toggle = "<leader>os",
  },
  
  -- Custom octocode command path (if not in PATH)
  command = "octocode",
  
  -- Quiet mode - suppress notifications
  silent = false,
})
```

> **That's it!** No complex configuration needed. The plugin automatically:
> - Starts background indexing when Neovim opens
> - Watches for file changes and re-indexes
> - Cleans up processes when Neovim exits

## 🚀 Usage

### 🎯 Quick Start

1. **Install the plugin** (see Installation section)
2. **Open Neovim** in your project directory
3. **Wait a moment** - octocode automatically starts indexing in the background
4. **Search your code**: Press `<leader>os` or run `:Octocode`

> **Note**: The first search might take a moment while initial indexing completes. Subsequent searches are instant!

### 🔄 How It Works

**Automatic & Seamless:**

1. **Plugin loads** → `octocode watch` starts automatically in background
2. **Files indexed** → Your codebase is analyzed and indexed
3. **Live updates** → File changes trigger re-indexing automatically  
4. **Search ready** → Once indexed, searches are lightning fast
5. **Clean exit** → Process stops automatically when you close Neovim

**First-time setup:**
- Open Neovim in your project directory
- Wait ~10-30 seconds for initial indexing (depends on project size)
- Start searching with `<leader>os`

**Subsequent sessions:**
- Indexing resumes instantly from where it left off
- Only changed files are re-indexed
- Search is available immediately

> **💡 Pro tip:** You can check indexing status by running `ps aux | grep "octocode watch"` in terminal

### 📝 Search Workflow

1. **Open search**: `<leader>os` or `:Octocode`
2. **Type your query** in natural language
3. **Auto-search**: Just press `Esc` - search executes automatically
4. **Switch modes**: `ma` (All), `mc` (Code), `md` (Docs), `mt` (Text)
5. **Navigate**: Use vim motions, press `<Enter>` to jump to code
6. **Close**: Press `q`

### 🔍 Search Modes

- **All**: Comprehensive search across all content types
- **Code**: Focus on functions, classes, and code logic
- **Docs**: Search documentation, comments, and markdown
- **Text**: Plain text content and strings

### 💡 Example Queries

```
# Natural language works best:
"user authentication flow"
"how to connect to database"
"error handling in payment processing"
"LSTM training pipeline"
"websocket connection logic"
"API rate limiting implementation"
```

## ⌨️ Keymaps

### Global
- `<leader>os` - Toggle search interface

### Search Interface
- `gi` - Jump to input line
- `gr` - Jump to results
- `ma` / `mc` / `md` / `mt` - Switch modes (All/Code/Docs/Text)
- `<Enter>` - Open file at line (when on result)
- `dd` - Clear input line
- `q` or `<Esc>` - Close interface
- `?` - Show help (coming soon)

## 🎨 Interface Preview

*Clean, focused search interface:*
```
┌─ Search Query [All] ─────────────────────────────────┐
│ user authentication flow                             │
│ -- Modes: (a)ll (c)ode (d)ocs (t)ext | <Esc> to run │
└──────────────────────────────────────────────────────┘

┌─ Results ────────────────────────────────────────────┐
│ === Search Results ===                               │
│                                                      │
│ 📄 Code Results:                                     │
│                                                      │
│   auth/login.rs:45-67 (0.892)                       │
│   ├─ handle_user_login()                            │
│   └─ User authentication with JWT tokens            │
│                                                      │
│   middleware/auth.rs:12-34 (0.847)                  │
│   ├─ verify_token()                                 │
│   └─ Token validation middleware                    │
│                                                      │
│ 📚 Documentation:                                    │
│                                                      │
│   docs/auth.md:23-45 (0.756)                        │
│   └─ Authentication flow diagram and setup          │
│                                                      │
│ Press <Enter> to jump to code                       │
└──────────────────────────────────────────────────────┘
```

## 🔧 Advanced Configuration

```lua
require("octocode").setup({
  -- Keybindings
  keymaps = {
    toggle = "<leader>os",  -- Change the toggle key
  },
  
  -- CLI command path (if not in PATH)
  command = "octocode",  -- or "/path/to/octocode"
  
  -- Suppress notifications
  silent = false,  -- Set to true for quiet mode
})
```

## 📚 API Reference

```lua
-- Open search interface
require("octocode.ui").toggle()
require("octocode.ui").open()
require("octocode.ui").close()

-- Execute search programmatically
require("octocode.search").execute(query, mode, results_buf)

-- Manual control (rarely needed)
require("octocode.watch").start()  -- Start watch process
require("octocode.watch").stop()   -- Stop watch process
```

## ❓ FAQ

**Q: Do I need to run `octocode index` manually?**  
A: No! The plugin automatically starts `octocode watch` which handles indexing and updates.

**Q: How do I know when indexing is complete?**  
A: Try a search - if you get results, you're ready! For large projects, initial indexing may take a minute.

**Q: Can I use this in multiple Neovim instances?**  
A: Yes! Each instance manages its own indexing process safely.

**Q: What if I don't want auto-indexing?**  
A: The plugin is designed for auto-indexing. For manual control, use the octocode CLI directly.

**Q: Does this work with large codebases?**  
A: Yes! octocode is optimized for large projects. Initial indexing may take time, but subsequent searches are fast.

## 🐛 Troubleshooting

### "No results found"
- **Wait for indexing**: First-time indexing may take a moment
- **Check octocode**: Run `octocode index` manually to verify it works
- **Try different queries**: Use natural language descriptions

### "Command not found"
```bash
# Verify octocode is installed:
which octocode
octocode --version

# Install if missing:
cargo install octocode
```

### Search not working?
1. **Check if indexing completed**: Look for `octocode watch` process
2. **Manual index**: Run `octocode index` in your project root
3. **Verify project**: Ensure you're in a git repository or valid project

### Performance tips
- **Large projects**: Initial indexing may take time, be patient
- **Exclude files**: Use `.gitignore` to skip unnecessary files
- **Update octocode**: Keep the CLI tool updated for best performance

## 🤝 Contributing

We welcome contributions! Feel free to:
- Report bugs or request features via Issues
- Submit Pull Requests with improvements
- Share your experience and feedback

## 📄 License

Apache License 2.0 — see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- Powered by [octocode](https://github.com/Muvon/octocode) - the intelligent code indexer
- Built with modern Neovim best practices
- Inspired by the need for better code search

---

**Made with ❤️ for the Neovim community**
