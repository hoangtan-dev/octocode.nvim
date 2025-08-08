-- UI module for real split window interface

local M = {}
local config = require("octocode").config

-- State management
local state = {
  input_buf = nil,
  input_win = nil,
  results_buf = nil,
  results_win = nil,
  current_mode = nil,
  is_open = false,
  original_win = nil,
}

-- Create the search panel using real vim splits
local function create_search_panel()
  -- Store original window
  state.original_win = vim.api.nvim_get_current_win()
  
  -- Create vertical split (left side)
  vim.cmd("leftabove vsplit")
  
  -- Resize to half screen
  local half_width = math.floor(vim.o.columns / 2)
  vim.cmd("vertical resize " .. half_width)
  
  -- Create input buffer
  local input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, input_buf)
  local input_win = vim.api.nvim_get_current_win()
  
  -- Set input buffer properties
  vim.bo[input_buf].buftype = "nofile"
  vim.bo[input_buf].bufhidden = "wipe"
  vim.bo[input_buf].swapfile = false
  vim.bo[input_buf].filetype = "octocode-input"
  
  -- Create horizontal split for results
  vim.cmd("below split")
  
  -- Make input window small (3 lines)
  vim.cmd("wincmd k")
  vim.cmd("resize 3")
  vim.cmd("wincmd j")
  
  -- Create results buffer
  local results_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, results_buf)
  local results_win = vim.api.nvim_get_current_win()
  
  -- Set results buffer properties
  vim.bo[results_buf].buftype = "nofile"
  vim.bo[results_buf].bufhidden = "wipe"
  vim.bo[results_buf].swapfile = false
  vim.bo[results_buf].modifiable = false
  vim.bo[results_buf].filetype = "octocode-results"
  
  -- Go back to input window
  vim.api.nvim_set_current_win(input_win)
  
  return input_win, input_buf, results_win, results_buf
end

-- Setup keymaps for the search interface
local function setup_search_keymaps(input_buf, results_buf)
  if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then
    return
  end
  
  local opts = { buffer = input_buf, silent = true }
  
  -- Auto-search when leaving insert mode
  vim.api.nvim_create_autocmd("InsertLeave", {
    buffer = input_buf,
    callback = function()
      local query = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)[1] or ""
      if not query:match("^%s*$") then
        M.search(query)
      end
    end,
  })
  
  -- Close panel on 'q' in normal mode (not Escape)
  vim.keymap.set("n", "q", function()
    M.close()
  end, opts)
  
  -- Mode switching in normal mode
  vim.keymap.set("n", config.keymaps.mode_all, function()
    M.set_mode("All")
    -- Re-search with new mode
    local query = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)[1] or ""
    if not query:match("^%s*$") then
      M.search(query)
    end
  end, opts)
  
  vim.keymap.set("n", config.keymaps.mode_code, function()
    M.set_mode("Code")
    local query = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)[1] or ""
    if not query:match("^%s*$") then
      M.search(query)
    end
  end, opts)
  
  vim.keymap.set("n", config.keymaps.mode_docs, function()
    M.set_mode("Docs")
    local query = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)[1] or ""
    if not query:match("^%s*$") then
      M.search(query)
    end
  end, opts)
  
  vim.keymap.set("n", config.keymaps.mode_text, function()
    M.set_mode("Text")
    local query = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)[1] or ""
    if not query:match("^%s*$") then
      M.search(query)
    end
  end, opts)
  
  -- Navigate between input and results
  vim.keymap.set("n", "<C-j>", function()
    if state.results_win and vim.api.nvim_win_is_valid(state.results_win) then
      vim.api.nvim_set_current_win(state.results_win)
    end
  end, opts)
end

-- Setup keymaps for results window
local function setup_results_keymaps(results_buf)
  if not results_buf or not vim.api.nvim_buf_is_valid(results_buf) then
    return
  end
  
  local opts = { buffer = results_buf, silent = true }
  
  -- Close panel on 'q' (not Escape)
  vim.keymap.set("n", "q", function()
    M.close()
  end, opts)
  
  -- Open file on Enter
  vim.keymap.set("n", config.keymaps.select, function()
    local line = vim.api.nvim_get_current_line()
    require("octocode.search").open_result(line)
  end, opts)
  
  -- Navigate back to input
  vim.keymap.set("n", "<C-k>", function()
    if state.input_win and vim.api.nvim_win_is_valid(state.input_win) then
      vim.api.nvim_set_current_win(state.input_win)
    end
  end, opts)
end

-- Set search mode
function M.set_mode(mode)
  state.current_mode = mode
  -- Update status line or show mode in results
  if state.results_buf and vim.api.nvim_buf_is_valid(state.results_buf) then
    vim.bo[state.results_buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.results_buf, 0, 1, false, {
      "=== Octocode Search [" .. mode .. " Mode] ==="
    })
    vim.bo[state.results_buf].modifiable = false
  end
end

-- Open search interface
function M.open()
  if state.is_open then
    return
  end
  
  state.current_mode = config.default_mode
  
  -- Create the search panel
  state.input_win, state.input_buf, state.results_win, state.results_buf = create_search_panel()
  
  -- Setup keymaps
  setup_search_keymaps(state.input_buf, state.results_buf)
  setup_results_keymaps(state.results_buf)
  
  -- Set initial mode display
  M.set_mode(state.current_mode)
  
  -- Add helpful text to input
  vim.api.nvim_buf_set_lines(state.input_buf, 0, -1, false, {
    "Type your search query here..."
  })
  
  -- Add initial help to results
  vim.bo[state.results_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.results_buf, 0, -1, false, {
    "=== Octocode Search [" .. state.current_mode .. " Mode] ===",
    "",
    "Instructions:",
    "• Type your query in the input field above",
    "• Press Escape to exit insert mode",
    "• Search will execute automatically when you leave insert mode",
    "• Use a/c/d/t to switch modes (All/Code/Docs/Text)",
    "• Use Ctrl+j/k to navigate between input and results",
    "• Press Enter on a result to open the file",
    "• Press q to close this panel",
    "",
    "Ready to search..."
  })
  vim.bo[state.results_buf].modifiable = false
  
  -- Position cursor on first line and enter insert mode
  vim.api.nvim_win_set_cursor(state.input_win, {1, 0})
  vim.cmd("startinsert")
  
  state.is_open = true
end

-- Close search interface
function M.close()
  -- Close the search panel windows
  if state.input_win and vim.api.nvim_win_is_valid(state.input_win) then
    vim.api.nvim_win_close(state.input_win, true)
  end
  if state.results_win and vim.api.nvim_win_is_valid(state.results_win) then
    vim.api.nvim_win_close(state.results_win, true)
  end
  
  -- Return to original window if it still exists
  if state.original_win and vim.api.nvim_win_is_valid(state.original_win) then
    vim.api.nvim_set_current_win(state.original_win)
  end
  
  -- Reset state
  state.input_win = nil
  state.input_buf = nil
  state.results_win = nil
  state.results_buf = nil
  state.original_win = nil
  state.is_open = false
end

-- Toggle search interface
function M.toggle()
  if state.is_open then
    M.close()
  else
    M.open()
  end
end

-- Perform search
function M.search(query)
  if not query or query:match("^%s*$") then
    return
  end
  
  -- Hide input window and show results
  if state.input_win and vim.api.nvim_win_is_valid(state.input_win) then
    vim.api.nvim_win_hide(state.input_win)
  end
  
  if state.results_win and vim.api.nvim_win_is_valid(state.results_win) then
    vim.api.nvim_win_show(state.results_win)
    vim.api.nvim_set_current_win(state.results_win)
  end
  
  -- Show loading message in results
  if state.results_buf and vim.api.nvim_buf_is_valid(state.results_buf) then
    vim.bo[state.results_buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.results_buf, 0, -1, false, {
      "=== Octocode Search [" .. state.current_mode .. " Mode] ===",
      "",
      "🔍 Searching: " .. query,
      "",
      "Please wait..."
    })
    vim.bo[state.results_buf].modifiable = false
  
    -- Perform actual search
    require("octocode.search").execute(query, state.current_mode, state.results_buf)
  end
end

return M