-- Single window UI for octocode search

local M = {}
local config = require("octocode").config

-- State management
local state = {
  search_buf = nil,
  search_win = nil,
  current_mode = nil,
  is_open = false,
  original_win = nil,
  input_start_line = 1,
  results_start_line = 5,
}

-- Create single search window
local function create_search_window()
  -- Store original window
  state.original_win = vim.api.nvim_get_current_win()
  
  -- Create left split (50% width)
  vim.cmd("leftabove vsplit")
  vim.cmd("vertical resize " .. math.floor(vim.o.columns / 2))
  
  -- Create single buffer for everything
  local search_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, search_buf)
  local search_win = vim.api.nvim_get_current_win()
  
  -- Set buffer properties - normal editable buffer
  vim.bo[search_buf].buftype = ""
  vim.bo[search_buf].swapfile = false
  vim.bo[search_buf].filetype = "octocode"
  
  return search_win, search_buf
end

-- Update the display with input and results
local function update_display(query, results_lines)
  if not state.search_buf or not vim.api.nvim_buf_is_valid(state.search_buf) then
    return
  end
  
  local lines = {}
  
  -- Input section
  table.insert(lines, "Search Query: " .. (query or ""))
  table.insert(lines, "Mode: [" .. (state.current_mode or "All") .. "] | Use <leader>a/c/d/t to switch modes")
  table.insert(lines, "")
  table.insert(lines, string.rep("=", 50))
  
  -- Results section
  if results_lines and #results_lines > 0 then
    for _, line in ipairs(results_lines) do
      table.insert(lines, line)
    end
  else
    table.insert(lines, "")
    table.insert(lines, "=== Octocode Search Results ===")
    table.insert(lines, "")
    table.insert(lines, "Instructions:")
    table.insert(lines, "• Edit the query above and press <Esc> to search")
    table.insert(lines, "• Use <leader>a/c/d/t for modes (All/Code/Docs/Text)")
    table.insert(lines, "• Press <Enter> on a result to open file in right panel")
    table.insert(lines, "• Press q to close this panel")
    table.insert(lines, "• All vim commands work: 9j, dd, yy, etc.")
    table.insert(lines, "")
    table.insert(lines, "Ready to search...")
  end
  
  -- Update buffer content
  vim.api.nvim_buf_set_lines(state.search_buf, 0, -1, false, lines)
  
  -- Update line markers
  state.input_start_line = 1
  state.results_start_line = 5
end

-- Setup keymaps for single window
local function setup_keymaps(search_buf)
  local opts = { buffer = search_buf, silent = true }
  
  -- Auto-search when leaving insert mode (only if on input line)
  vim.api.nvim_create_autocmd("InsertLeave", {
    buffer = search_buf,
    callback = function()
      local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
      
      -- Only search if we're on the input line
      if cursor_line == state.input_start_line then
        local line = vim.api.nvim_buf_get_lines(search_buf, 0, 1, false)[1] or ""
        local query = line:match("Search Query: (.*)") or ""
        query = query:gsub("^%s*", ""):gsub("%s*$", "")
        
        if query ~= "" then
          M.search(query)
        end
      end
    end,
  })
  
  -- Smart editing on input line
  vim.api.nvim_create_autocmd("InsertEnter", {
    buffer = search_buf,
    callback = function()
      local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
      
      -- If entering insert mode on input line, position cursor after "Search Query: "
      if cursor_line == state.input_start_line then
        local line = vim.api.nvim_buf_get_lines(search_buf, 0, 1, false)[1] or ""
        if line:match("^Search Query: $") then
          -- Clear and start fresh
          vim.api.nvim_buf_set_lines(search_buf, 0, 1, false, {"Search Query: "})
          vim.api.nvim_win_set_cursor(0, {1, 14}) -- Position after "Search Query: "
        end
      end
    end,
  })
  
  -- Close with 'q'
  vim.keymap.set("n", "q", M.close, opts)
  
  -- Mode switching
  vim.keymap.set("n", "<leader>a", function() M.set_mode("All") end, opts)
  vim.keymap.set("n", "<leader>c", function() M.set_mode("Code") end, opts)
  vim.keymap.set("n", "<leader>d", function() M.set_mode("Docs") end, opts)
  vim.keymap.set("n", "<leader>t", function() M.set_mode("Text") end, opts)
  
  -- Open file on Enter (if on a result line)
  vim.keymap.set("n", "<CR>", function()
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    
    -- Only open file if we're in the results section
    if cursor_line >= state.results_start_line then
      local line = vim.api.nvim_get_current_line()
      require("octocode.search").open_result(line)
    end
  end, opts)
  
  -- Quick jump to input line
  vim.keymap.set("n", "gi", function()
    vim.api.nvim_win_set_cursor(0, {state.input_start_line, 14})
    vim.cmd("startinsert")
  end, opts)
  
  -- Quick jump to results
  vim.keymap.set("n", "gr", function()
    vim.api.nvim_win_set_cursor(0, {state.results_start_line, 0})
  end, opts)
end

-- Set search mode
function M.set_mode(mode)
  state.current_mode = mode
  
  -- Get current query
  local query = ""
  if state.search_buf and vim.api.nvim_buf_is_valid(state.search_buf) then
    local line = vim.api.nvim_buf_get_lines(state.search_buf, 0, 1, false)[1] or ""
    query = line:match("Search Query: (.*)") or ""
    query = query:gsub("^%s*", ""):gsub("%s*$", "")
  end
  
  -- Update display and re-search if we have a query
  update_display(query)
  if query ~= "" then
    M.search(query)
  end
end

-- Open search interface
function M.open()
  if state.is_open then
    return
  end
  
  state.current_mode = config.default_mode
  
  -- Create single window
  state.search_win, state.search_buf = create_search_window()
  
  -- Setup keymaps
  setup_keymaps(state.search_buf)
  
  -- Initialize display
  update_display("")
  
  -- Position cursor on input line and enter insert mode
  vim.api.nvim_win_set_cursor(state.search_win, {state.input_start_line, 14})
  vim.cmd("startinsert")
  
  state.is_open = true
end

-- Close interface
function M.close()
  if state.search_win and vim.api.nvim_win_is_valid(state.search_win) then
    vim.api.nvim_win_close(state.search_win, true)
  end
  
  if state.original_win and vim.api.nvim_win_is_valid(state.original_win) then
    vim.api.nvim_set_current_win(state.original_win)
  end
  
  state = {
    search_buf = nil,
    search_win = nil,
    current_mode = nil,
    is_open = false,
    original_win = nil,
    input_start_line = 1,
    results_start_line = 5,
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

-- Perform search and update results
function M.search(query)
  if not query or query:match("^%s*$") then
    return
  end
  
  -- Show loading
  update_display(query, {
    "",
    "=== Octocode Search Results ===",
    "",
    "🔍 Searching: " .. query,
    "Mode: " .. state.current_mode,
    "",
    "Please wait..."
  })
  
  -- Execute search
  require("octocode.search").execute_single_window(query, state.current_mode, function(results_lines)
    update_display(query, results_lines)
  end)
end

return M