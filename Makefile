# Makefile for octocode.nvim development and testing

.PHONY: test lint format install clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  test     - Run tests"
	@echo "  lint     - Run linting"
	@echo "  format   - Format Lua code"
	@echo "  install  - Install plugin locally for testing"
	@echo "  clean    - Clean temporary files"
	@echo "  help     - Show this help"

# Test the plugin
test:
	@echo "Testing octocode.nvim..."
	@nvim --headless --noplugin -u tests/minimal_init.lua -c "lua require('tests.test_runner').run_all()" -c "qa!"

# Lint Lua files
lint:
	@echo "Linting Lua files..."
	@if command -v luacheck >/dev/null 2>&1; then \
		luacheck lua/ --globals vim; \
	else \
		echo "luacheck not found. Install with: luarocks install luacheck"; \
	fi

# Format Lua files
format:
	@echo "Formatting Lua files..."
	@if command -v stylua >/dev/null 2>&1; then \
		stylua lua/ plugin/ --config-path .stylua.toml; \
	else \
		echo "stylua not found. Install with: cargo install stylua"; \
	fi

# Install plugin locally for testing
install:
	@echo "Installing plugin locally..."
	@mkdir -p ~/.local/share/nvim/site/pack/local/start/octocode.nvim
	@cp -r . ~/.local/share/nvim/site/pack/local/start/octocode.nvim/
	@echo "Plugin installed. Restart Neovim to load."

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -name "*.tmp" -delete
	@find . -name ".DS_Store" -delete

# Check if octocode CLI is available
check-deps:
	@echo "Checking dependencies..."
	@if command -v octocode >/dev/null 2>&1; then \
		echo "✓ octocode CLI found: $$(octocode --version)"; \
	else \
		echo "✗ octocode CLI not found. Please install it first."; \
		exit 1; \
	fi
	@if nvim --version | head -1 | grep -qE "v0\.(8|9|[1-9][0-9])|v[1-9]"; then \
		echo "✓ Neovim version compatible: $$(nvim --version | head -1)"; \
	else \
		echo "✗ Neovim 0.8+ required, found: $$(nvim --version | head -1)"; \
		exit 1; \
	fi

# Development setup
dev-setup: check-deps
	@echo "Setting up development environment..."
	@echo "Creating test configuration..."
	@mkdir -p tests
	@echo "Development setup complete!"