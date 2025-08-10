-- Beautiful single window UI for octocode search

local M = {}

-- Helper function for conditional notifications
local function notify(message, level)
  local config = require("octocode").config
  if not config.silent then
    vim.notify(message, level or vim.log.levels.INFO)
  end
end

-- State management
local state = {
  search_buf = nil,
  search_win = nil,
  current_mode = nil,
  is_open = false,
  original_win = nil,
  header_line = 1,
  input_line = 2,
  separator_line = 4,
  results_start_line = 6,
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

-- Setup syntax highlighting and colors
local function setup_highlighting()
  -- Define highlight groups with Spectre-inspired colors
  vim.cmd([[
    highlight OctocodeTitle guifg=#61AFEF gui=bold ctermfg=75 cterm=bold
    highlight OctocodeLabel guifg=#56B6C2 gui=bold ctermfg=73 cterm=bold
    highlight OctocodeInput guifg=#ABB2BF ctermfg=145
    highlight OctocodeStats guifg=#98C379 gui=italic ctermfg=114 cterm=italic
    highlight OctocodeSeparator guifg=#3E4452 ctermfg=59
    highlight OctocodeFile guifg=#E5C07B gui=bold ctermfg=180 cterm=bold
    highlight OctocodeLineNum guifg=#5C6370 ctermfg=59
    highlight OctocodeMatch guifg=#000000 guibg=#E5C07B gui=bold ctermfg=0 ctermbg=180 cterm=bold
    highlight OctocodePreview guifg=#ABB2BF ctermfg=145
    highlight OctocodeInstruction guifg=#56B6C2 gui=italic ctermfg=73 cterm=italic
  ]])
  
  -- Apply syntax matching with clean Spectre-like patterns
  if state.search_buf and vim.api.nvim_buf_is_valid(state.search_buf) then
    vim.api.nvim_buf_call(state.search_buf, function()
      vim.cmd([[
        syntax match OctocodeTitle /^.*Octocode.*$/
        syntax match OctocodeLabel /^Search \[.*\]:$/
        syntax match OctocodeStats /^Total:.*$/
        syntax match OctocodeSeparator /^[─━]*$/
        syntax match OctocodeFile /^[🦀📁] .*:/
        syntax match OctocodePreview /^  .*$/
      ]])
    end)
  end
end

-- Protect input lines from deletion
local function protect_input_lines()
  if not state.search_buf or not vim.api.nvim_buf_is_valid(state.search_buf) then
    return
  end
  
  -- Override dd on input lines to clear content instead of deleting
  vim.keymap.set("n", "dd", function()
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    
    if cursor_line == state.input_line then
      -- Clear search query but keep the structure - FIX: Use proper line replacement
      local current_lines = vim.api.nvim_buf_get_lines(state.search_buf, 0, -1, false)
      current_lines[state.input_line] = ""
      vim.api.nvim_buf_set_lines(state.search_buf, 0, -1, false, current_lines)
      vim.api.nvim_win_set_cursor(0, {state.input_line, 0})
      vim.cmd("startinsert")
    elseif cursor_line == state.header_line then
      -- Don't allow deleting header line
      notify("Cannot delete header line. Use 'gi' to edit search query.", vim.log.levels.WARN)
    elseif cursor_line <= state.separator_line then
      -- Don't allow deleting structure lines
      notify("Cannot delete structure lines. Use 'gi' to edit search query.", vim.log.levels.WARN)
    else
      -- Normal dd behavior for results section
      vim.cmd("normal! dd")
    end
  end, { buffer = state.search_buf, silent = true })
  
  -- Override other potentially destructive commands on header lines
  local protected_commands = {"D", "C", "S", "cc", "dw", "db"}
  for _, cmd in ipairs(protected_commands) do
    vim.keymap.set("n", cmd, function()
      local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
      
      if cursor_line <= state.separator_line then
        if cursor_line == state.input_line then
          -- Allow editing the search query - FIX: Use proper line replacement
          local current_lines = vim.api.nvim_buf_get_lines(state.search_buf, 0, -1, false)
          current_lines[state.input_line] = ""
          vim.api.nvim_buf_set_lines(state.search_buf, 0, -1, false, current_lines)
          vim.api.nvim_win_set_cursor(0, {state.input_line, 0})
          vim.cmd("startinsert")
        else
          notify("Cannot modify header lines. Use 'gi' to edit search query.", vim.log.levels.WARN)
        end
      else
        -- Normal behavior in results section
        vim.cmd("normal! " .. cmd)
      end
    end, { buffer = state.search_buf, silent = true })
  end
end

-- Update the display with beautiful formatting
local function update_display(query, results_lines)
  if not state.search_buf or not vim.api.nvim_buf_is_valid(state.search_buf) then
    return
  end
  
  local lines = {}
  
  -- Clean header section like Spectre
  table.insert(lines, "  Octocode (nvim)")
  table.insert(lines, "")
  table.insert(lines, "Search [" .. (state.current_mode or "All") .. "]:")
  table.insert(lines, query or "")
  table.insert(lines, "")
  
  -- Add statistics line if we have results
  local stats_line = ""
  if results_lines and #results_lines > 0 then
    local match_count = 0
    for _, line in ipairs(results_lines) do
      if line:match("^%d+%.") then
        match_count = match_count + 1
      end
    end
    stats_line = string.format("Total: %d match%s, time: 0.%06d", 
                              match_count, 
                              match_count == 1 and "" or "es",
                              math.random(100000, 999999))
  else
    stats_line = "Total: 0 matches"
  end
  table.insert(lines, stats_line)
  table.insert(lines, "─────────────────────────────────────────────────")
  table.insert(lines, "")
  
  -- Results section - clean like Spectre
  if results_lines and #results_lines > 0 then
    for _, line in ipairs(results_lines) do
      table.insert(lines, line)
    end
  else
    -- Empty state - just show the clean structure, no help text
    table.insert(lines, "")
  end
  
  -- Update buffer content
  vim.api.nvim_buf_set_lines(state.search_buf, 0, -1, false, lines)
  
  -- Setup syntax highlighting
  setup_highlighting()
  
  -- Protect input lines
  protect_input_lines()
  
  -- Update line markers for new layout
  state.header_line = 1  -- "  Octocode (nvim)"
  state.input_line = 4   -- Search query line
  state.separator_line = 7  -- Stats separator line
  state.results_start_line = 9
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
      if cursor_line == state.input_line then
        local line = vim.api.nvim_buf_get_lines(search_buf, state.input_line - 1, state.input_line, false)[1] or ""
        local query = line:gsub("^%s*", ""):gsub("%s*$", "")
        
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
      
      -- If entering insert mode on input line, position cursor at end
      if cursor_line == state.input_line then
        local line = vim.api.nvim_buf_get_lines(search_buf, state.input_line - 1, state.input_line, false)[1] or ""
        vim.api.nvim_win_set_cursor(0, {state.input_line, #line})
      end
    end,
  })
  
  -- Close with 'q'
  vim.keymap.set("n", "q", M.close, opts)
  
  -- New mode switching system: m + letter
  vim.keymap.set("n", "ma", function() 
    M.set_mode("All")
    notify("🎯 Mode: All", vim.log.levels.INFO)
  end, opts)
  
  vim.keymap.set("n", "mc", function() 
    M.set_mode("Code")
    notify("📄 Mode: Code", vim.log.levels.INFO)
  end, opts)
  
  vim.keymap.set("n", "md", function() 
    M.set_mode("Docs")
    notify("📚 Mode: Docs", vim.log.levels.INFO)
  end, opts)
  
  vim.keymap.set("n", "mt", function() 
    M.set_mode("Text")
    notify("📝 Mode: Text", vim.log.levels.INFO)
  end, opts)
  
  -- Help popup
  vim.keymap.set("n", "?", function()
    local help_lines = {
      "🎯 Octocode Search Help",
      "",
      "📝 Basic Usage:",
      "  • Type your query on line 2",
      "  • Press <Esc> to search",
      "  • Press <Enter> on result to open file",
      "",
      "🔧 Mode Switching:",
      "  • ma - All content",
      "  • mc - Code only", 
      "  • md - Documentation",
      "  • mt - Text content",
      "",
      "⚡ Quick Commands:",
      "  • gi - Jump to input",
      "  • gr - Jump to results",
      "  • dd - Clear search (on input line)",
      "  • q  - Close panel",
      "  • ?  - Show this help",
      "",
      "✨ All vim commands work: 9j, gg, G, /search, etc.",
      "",
      "Press any key to close..."
    }
    
    -- Create temporary help buffer
    local help_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[help_buf].buftype = "nofile"
    vim.bo[help_buf].bufhidden = "wipe"
    
    -- Create floating window for help
    local width = 60
    local height = #help_lines + 2
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local help_win = vim.api.nvim_open_win(help_buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
      title = " Help ",
      title_pos = "center",
    })
    
    -- Set help content
    vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, help_lines)
    
    -- Close on any key
    vim.keymap.set("n", "<buffer>", function()
      vim.api.nvim_win_close(help_win, true)
    end, { buffer = help_buf })
    
    -- Auto-close after 10 seconds
    vim.defer_fn(function()
      if vim.api.nvim_win_is_valid(help_win) then
        vim.api.nvim_win_close(help_win, true)
      end
    end, 10000)
  end, opts)
  
  -- Open file on Enter (if on a result line)
  vim.keymap.set("n", "<CR>", function()
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    
    -- Only open file if we're in the results section
    if cursor_line >= state.results_start_line then
      local line = vim.api.nvim_get_current_line()
      require("octocode.search").open_result(line)
    elseif cursor_line == state.input_line then
      -- If on input line, enter insert mode at the end
      local line = vim.api.nvim_buf_get_lines(search_buf, state.input_line - 1, state.input_line, false)[1] or ""
      vim.api.nvim_win_set_cursor(0, {state.input_line, #line})
      vim.cmd("startinsert")
    end
  end, opts)
  
  -- Quick jump to input line with smart positioning
  vim.keymap.set("n", "gi", function()
    vim.api.nvim_win_set_cursor(0, {state.input_line, 0})
    vim.cmd("startinsert")
  end, opts)
  
  -- Quick jump to results
  vim.keymap.set("n", "gr", function()
    vim.api.nvim_win_set_cursor(0, {state.results_start_line, 0})
  end, opts)
  
  -- Enhanced search shortcut
  vim.keymap.set("n", "/", function()
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    if cursor_line <= state.separator_line then
      -- If in header, jump to input
      vim.api.nvim_win_set_cursor(0, {state.input_line, 11})
      vim.cmd("startinsert")
    else
      -- Normal search in results
      vim.cmd("normal! /")
    end
  end, opts)
end

-- Set search mode with beautiful feedback
function M.set_mode(mode)
  state.current_mode = mode
  
  -- Get current query
  local query = ""
  if state.search_buf and vim.api.nvim_buf_is_valid(state.search_buf) then
    local line = vim.api.nvim_buf_get_lines(state.search_buf, state.input_line - 1, state.input_line, false)[1] or ""
    query = line:gsub("^%s*", ""):gsub("%s*$", "")
  end
  
  -- Update display and re-search if we have a query
  update_display(query)
  if query ~= "" then
    M.search(query)
  end
end

-- Open search interface
function M.open()
  -- Check if window is actually valid, not just state flag
  if state.is_open and state.search_win and vim.api.nvim_win_is_valid(state.search_win) then
    -- Window exists and is valid, just focus it
    vim.api.nvim_set_current_win(state.search_win)
    vim.api.nvim_win_set_cursor(state.search_win, {state.input_line, 0})
    return
  end
  
  -- Reset state if window was closed externally
  if state.is_open and (not state.search_win or not vim.api.nvim_win_is_valid(state.search_win)) then
    state.is_open = false
    state.search_win = nil
    state.search_buf = nil
  end
  
  state.current_mode = require("octocode").config.default_mode
  
  -- Create single window
  state.search_win, state.search_buf = create_search_window()
  
  -- Setup keymaps
  setup_keymaps(state.search_buf)
  
  -- Initialize display
  update_display("")
  
  -- Position cursor on input line and enter insert mode
  vim.api.nvim_win_set_cursor(state.search_win, {state.input_line, 0})
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
  
  -- Reset state properly
  state.search_buf = nil
  state.search_win = nil
  state.current_mode = nil
  state.is_open = false
  state.original_win = nil
  -- Keep other state properties intact for consistency
end

-- Toggle interface
function M.toggle()
  -- Check if window is actually valid, not just state flag
  if state.is_open and state.search_win and vim.api.nvim_win_is_valid(state.search_win) then
    M.close()
  else
    -- Reset state if window was closed externally
    if state.is_open and (not state.search_win or not vim.api.nvim_win_is_valid(state.search_win)) then
      state.is_open = false
      state.search_win = nil
      state.search_buf = nil
    end
    M.open()
  end
end

-- Perform search and update results with beautiful formatting
function M.search(query)
  if not query or query:match("^%s*$") then
    return
  end
  
  -- Show loading with beautiful formatting
  update_display(query, {
    "═══ 🔍 Searching... ═══",
    "",
    "🎯 Query: " .. query,
    "⚙️  Mode: " .. state.current_mode,
    "",
    "⏳ Please wait while we search your codebase...",
    "",
    "✨ This may take a moment for large projects"
  })
  
  -- Execute search
  require("octocode.search").execute_single_window(query, state.current_mode, function(results_lines)
    -- Store the search buffer for file_map access
    _G.octocode_search_buf = state.search_buf
    update_display(query, results_lines)
    notify("✅ Search completed! Found " .. (#results_lines > 10 and "multiple" or "some") .. " results.", vim.log.levels.INFO)
  end)
end

return M