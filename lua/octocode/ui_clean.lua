-- COMPLETELY CLEAN UI module - NO floating windows at all

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

-- Create search panel using ONLY vim commands
local function create_search_panel()
  -- Store original window
  state.original_win = vim.api.nvim_get_current_win()
  
  -- Create left split (50% width)
  vim.cmd("leftabove vsplit")
  vim.cmd("vertical resize " .. math.floor(vim.o.columns / 2))
  
  -- Create input buffer in current window
  local input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, input_buf)
  local input_win = vim.api.nvim_get_current_win()
  
  -- Set buffer options - make it editable like a normal buffer
  vim.bo[input_buf].buftype = ""  -- Normal buffer, not "nofile"
  vim.bo[input_buf].swapfile = false
  vim.bo[input_buf].filetype = "octocode-input"
  
  -- Create bottom split for results
  vim.cmd("below split")
  vim.cmd("wincmd k") -- Go to top (input)
  vim.cmd("resize 3")  -- Make input small
  vim.cmd("wincmd j") -- Go to bottom (results)
  
  -- Create results buffer
  local results_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, results_buf)
  local results_win = vim.api.nvim_get_current_win()
  
  -- Set results buffer options
  vim.bo[results_buf].buftype = "nofile"  -- Keep nofile for results
  vim.bo[results_buf].swapfile = false
  vim.bo[results_buf].modifiable = false
  vim.bo[results_buf].filetype = "octocode-results"
  
  -- Return to input window
  vim.api.nvim_set_current_win(input_win)
  
  return input_win, input_buf, results_win, results_buf
end

-- Setup keymaps
local function setup_keymaps(input_buf, results_buf)
  -- Input buffer keymaps - MINIMAL to preserve vim functionality
  local input_opts = { buffer = input_buf, silent = true }
  
  -- Auto-search on leaving insert mode
  vim.api.nvim_create_autocmd("InsertLeave", {
    buffer = input_buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
      local query = table.concat(lines, " "):gsub("^%s*", ""):gsub("%s*$", "")
      
      -- Skip if it's just the placeholder
      if query ~= "" and query ~= "Type your search query here..." then
        M.search(query)
      end
    end,
  })
  
  -- Smart placeholder removal on insert mode
  vim.api.nvim_create_autocmd("InsertEnter", {
    buffer = input_buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
      local content = table.concat(lines, "\n")
      
      -- Remove placeholder text when entering insert mode
      if content == "Type your search query here..." then
        vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {""})
      end
    end,
  })
  
  -- ONLY override essential keys, let vim handle the rest
  -- Close with 'q' ONLY in normal mode and ONLY if buffer is empty or placeholder
  vim.keymap.set("n", "q", function()
    local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
    local content = table.concat(lines, "\n"):gsub("^%s*", ""):gsub("%s*$", "")
    
    -- Only close if buffer is empty or has placeholder
    if content == "" or content == "Type your search query here..." then
      M.close()
    else
      -- Let vim handle 'q' normally (record macro)
      vim.cmd("normal! q")
    end
  end, input_opts)
  
  -- Mode switching - use leader key to avoid conflicts
  vim.keymap.set("n", "<leader>a", function() M.set_mode("All") end, input_opts)
  vim.keymap.set("n", "<leader>c", function() M.set_mode("Code") end, input_opts)
  vim.keymap.set("n", "<leader>d", function() M.set_mode("Docs") end, input_opts)
  vim.keymap.set("n", "<leader>t", function() M.set_mode("Text") end, input_opts)
  
  -- Navigation between panels
  vim.keymap.set("n", "<C-j>", function()
    if state.results_win and vim.api.nvim_win_is_valid(state.results_win) then
      vim.api.nvim_set_current_win(state.results_win)
    end
  end, input_opts)
  
  -- Results buffer keymaps - MINIMAL to preserve vim functionality
  local results_opts = { buffer = results_buf, silent = true }
  
  -- Close with 'q' in results
  vim.keymap.set("n", "q", M.close, results_opts)
  
  -- Open file on Enter
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    require("octocode.search").open_result(line)
  end, results_opts)
  
  -- Navigation back to input
  vim.keymap.set("n", "<C-k>", function()
    if state.input_win and vim.api.nvim_win_is_valid(state.input_win) then
      vim.api.nvim_set_current_win(state.input_win)
    end
  end, results_opts)
  
  -- Mode switching in results too
  vim.keymap.set("n", "<leader>a", function() M.set_mode("All") end, results_opts)
  vim.keymap.set("n", "<leader>c", function() M.set_mode("Code") end, results_opts)
  vim.keymap.set("n", "<leader>d", function() M.set_mode("Docs") end, results_opts)
  vim.keymap.set("n", "<leader>t", function() M.set_mode("Text") end, results_opts)
end

-- Set search mode
function M.set_mode(mode)
  state.current_mode = mode
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
  
  -- Create panel
  state.input_win, state.input_buf, state.results_win, state.results_buf = create_search_panel()
  
  -- Setup keymaps
  setup_keymaps(state.input_buf, state.results_buf)
  
  -- Initialize content
  vim.api.nvim_buf_set_lines(state.input_buf, 0, -1, false, {
    "Type your search query here..."
  })
  
  vim.bo[state.results_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.results_buf, 0, -1, false, {
    "=== Octocode Search [" .. state.current_mode .. " Mode] ===",
    "",
    "Instructions:",
    "• Type query above, press Esc to search",
    "• Use <leader>a/c/d/t for modes (All/Code/Docs/Text)",
    "• Use Ctrl+j/k to navigate between panels",
    "• Press Enter on result to open file",
    "• Press q to close (when input is empty)",
    "• All vim commands work: 9j, dd, yy, etc.",
    "",
    "Ready to search..."
  })
  vim.bo[state.results_buf].modifiable = false
  
  -- Enter insert mode
  vim.cmd("startinsert")
  state.is_open = true
end

-- Close interface
function M.close()
  if state.input_win and vim.api.nvim_win_is_valid(state.input_win) then
    vim.api.nvim_win_close(state.input_win, true)
  end
  if state.results_win and vim.api.nvim_win_is_valid(state.results_win) then
    vim.api.nvim_win_close(state.results_win, true)
  end
  
  if state.original_win and vim.api.nvim_win_is_valid(state.original_win) then
    vim.api.nvim_set_current_win(state.original_win)
  end
  
  state = {
    input_buf = nil,
    input_win = nil,
    results_buf = nil,
    results_win = nil,
    current_mode = nil,
    is_open = false,
    original_win = nil,
  }
end

-- Toggle interface
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
    
    require("octocode.search").execute(query, state.current_mode, state.results_buf)
  end
end

return M