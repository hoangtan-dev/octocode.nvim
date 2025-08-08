-- Search module for octocode CLI integration

local M = {}
local config = require("octocode").config

-- Execute search using octocode CLI
function M.execute(query, mode, results_buf)
  -- Build command arguments
  local cmd = { config.command, "search", "--format=json" }
  
  -- Add mode-specific arguments
  if mode == "Code" then
    table.insert(cmd, "--mode=code")
  elseif mode == "Docs" then
    table.insert(cmd, "--mode=docs")
  elseif mode == "Text" then
    table.insert(cmd, "--mode=text")
  end
  -- "All" mode doesn't need additional arguments
  
  -- Add query
  table.insert(cmd, query)
  
  -- Execute command asynchronously
  local output = {}
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        vim.schedule(function()
          M.display_error(results_buf, "Error: " .. table.concat(data, "\n"))
        end)
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          local json_str = table.concat(output, "\n")
          M.parse_and_display(json_str, results_buf)
        else
          M.display_error(results_buf, "Command failed with exit code: " .. exit_code)
        end
      end)
    end,
  })
  
  if job_id <= 0 then
    M.display_error(results_buf, "Failed to start octocode command")
  end
end

-- Parse JSON results and display
function M.parse_and_display(json_str, results_buf)
  local ok, results = pcall(vim.json.decode, json_str)
  
  if not ok then
    M.display_error(results_buf, "Failed to parse JSON response")
    return
  end
  
  local lines = {}
  local file_map = {} -- Map line numbers to file info
  
  -- Add header
  table.insert(lines, "=== Octocode Search Results ===")
  table.insert(lines, "")
  
  -- Process code blocks
  if results.code_blocks and #results.code_blocks > 0 then
    table.insert(lines, "📄 Code Results:")
    table.insert(lines, "")
    
    for i, block in ipairs(results.code_blocks) do
      local line_num = #lines + 1
      file_map[line_num] = {
        path = block.path,
        start_line = block.start_line,
        end_line = block.end_line
      }
      
      -- Format result entry
      table.insert(lines, string.format("  %d. %s:%d-%d (%.3f)", 
        i, block.path, block.start_line, block.end_line, block.distance))
      
      if block.symbols and #block.symbols > 0 then
        table.insert(lines, string.format("     Symbols: %s", table.concat(block.symbols, ", ")))
      end
      
      -- Show preview of content (first few lines)
      if block.content then
        local content_lines = vim.split(block.content, "\n")
        local preview_lines = math.min(3, #content_lines)
        
        for j = 1, preview_lines do
          local line = content_lines[j]:gsub("^%s*", "     ") -- Indent
          if #line > 80 then
            line = line:sub(1, 77) .. "..."
          end
          table.insert(lines, line)
        end
        
        if #content_lines > preview_lines then
          table.insert(lines, "     ...")
        end
      end
      
      table.insert(lines, "")
    end
  end
  
  -- Process document blocks
  if results.document_blocks and #results.document_blocks > 0 then
    table.insert(lines, "📚 Document Results:")
    table.insert(lines, "")
    
    for i, block in ipairs(results.document_blocks) do
      local line_num = #lines + 1
      file_map[line_num] = {
        path = block.path,
        start_line = block.start_line,
        end_line = block.end_line
      }
      
      table.insert(lines, string.format("  %d. %s:%d-%d (%.3f)", 
        i, block.path, block.start_line, block.end_line, block.distance))
      
      if block.title then
        table.insert(lines, string.format("     Title: %s", block.title))
      end
      
      -- Show preview
      if block.content then
        local content_lines = vim.split(block.content, "\n")
        local preview_lines = math.min(2, #content_lines)
        
        for j = 1, preview_lines do
          local line = content_lines[j]:gsub("^%s*", "     ")
          if #line > 80 then
            line = line:sub(1, 77) .. "..."
          end
          table.insert(lines, line)
        end
      end
      
      table.insert(lines, "")
    end
  end
  
  -- Process text blocks
  if results.text_blocks and #results.text_blocks > 0 then
    table.insert(lines, "📝 Text Results:")
    table.insert(lines, "")
    
    for i, block in ipairs(results.text_blocks) do
      local line_num = #lines + 1
      file_map[line_num] = {
        path = block.path,
        start_line = block.start_line,
        end_line = block.end_line
      }
      
      table.insert(lines, string.format("  %d. %s:%d-%d (%.3f)", 
        i, block.path, block.start_line, block.end_line, block.distance))
      
      if block.content then
        local content_lines = vim.split(block.content, "\n")
        local preview_lines = math.min(2, #content_lines)
        
        for j = 1, preview_lines do
          local line = content_lines[j]:gsub("^%s*", "     ")
          if #line > 80 then
            line = line:sub(1, 77) .. "..."
          end
          table.insert(lines, line)
        end
      end
      
      table.insert(lines, "")
    end
  end
  
  -- Add footer with instructions
  table.insert(lines, "")
  table.insert(lines, "Press <Enter> on a result to open the file")
  table.insert(lines, "Press <Esc> to close")
  
  -- Store file map for navigation
  vim.b[results_buf].octocode_file_map = file_map
  
  -- Display results
  vim.bo[results_buf].modifiable = true
  vim.api.nvim_buf_set_lines(results_buf, 0, -1, false, lines)
  vim.bo[results_buf].modifiable = false
  
  -- Set syntax highlighting
  vim.bo[results_buf].filetype = "octocode-results"
end

-- Display error message
function M.display_error(results_buf, error_msg)
  local lines = {
    "=== Octocode Error ===",
    "",
    error_msg,
    "",
    "Please check:",
    "• Is 'octocode' command available in PATH?",
    "• Are you in a valid project directory?",
    "• Is the query format correct?",
    "",
    "Press <Esc> to close"
  }
  
  vim.bo[results_buf].modifiable = true
  vim.api.nvim_buf_set_lines(results_buf, 0, -1, false, lines)
  vim.bo[results_buf].modifiable = false
end

-- Execute search for single window interface
function M.execute_single_window(query, mode, callback)
  -- Build command arguments
  local cmd = { config.command, "search", "--format=json" }
  
  -- Add mode-specific arguments
  if mode == "Code" then
    table.insert(cmd, "--mode=code")
  elseif mode == "Docs" then
    table.insert(cmd, "--mode=docs")
  elseif mode == "Text" then
    table.insert(cmd, "--mode=text")
  end
  
  -- Add query
  table.insert(cmd, query)
  
  -- Execute command asynchronously
  local output = {}
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        vim.schedule(function()
          callback({
            "",
            "=== Octocode Error ===",
            "",
            "Error: " .. table.concat(data, "\n"),
            "",
            "Please check:",
            "• Is 'octocode' command available in PATH?",
            "• Are you in a valid project directory?",
            "• Is the query format correct?"
          })
        end)
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          local json_str = table.concat(output, "\n")
          local results_lines = M.parse_results_for_single_window(json_str)
          callback(results_lines)
        else
          callback({
            "",
            "=== Octocode Error ===",
            "",
            "Command failed with exit code: " .. exit_code,
            "",
            "Please check your octocode installation and query."
          })
        end
      end)
    end,
  })
  
  if job_id <= 0 then
    callback({
      "",
      "=== Octocode Error ===",
      "",
      "Failed to start octocode command",
      "",
      "Please check that octocode is installed and in PATH."
    })
  end
end

-- Parse results for single window display with beautiful formatting
function M.parse_results_for_single_window(json_str)
  local ok, results = pcall(vim.json.decode, json_str)
  
  if not ok then
    return {
      "═══ ❌ Error ═══",
      "",
      "🚨 Failed to parse search results",
      "",
      "▶ Please check your octocode version and query format",
      "▶ Try a simpler query or check your installation"
    }
  end
  
  local lines = {}
  local file_map = {} -- Store file info for opening
  
  -- Add beautiful header
  table.insert(lines, "═══ 🎯 Search Results ═══")
  table.insert(lines, "")
  
  -- Process code blocks
  if results.code_blocks and #results.code_blocks > 0 then
    table.insert(lines, "📄 Code Results:")
    table.insert(lines, "")
    
    for i, block in ipairs(results.code_blocks) do
      local line_num = #lines + 1
      file_map[line_num] = {
        path = block.path,
        start_line = block.start_line,
        end_line = block.end_line
      }
      
      -- Format result entry
      table.insert(lines, string.format("  %d. %s:%d-%d (%.3f)", 
        i, block.path, block.start_line, block.end_line, block.distance))
      
      if block.symbols and #block.symbols > 0 then
        table.insert(lines, string.format("     Symbols: %s", table.concat(block.symbols, ", ")))
      end
      
      -- Show preview of content (first few lines)
      if block.content then
        local content_lines = vim.split(block.content, "\n")
        local preview_lines = math.min(3, #content_lines)
        
        for j = 1, preview_lines do
          local line = content_lines[j]:gsub("^%s*", "     ") -- Indent
          if #line > 80 then
            line = line:sub(1, 77) .. "..."
          end
          table.insert(lines, line)
        end
        
        if #content_lines > preview_lines then
          table.insert(lines, "     ...")
        end
      end
      
      table.insert(lines, "")
    end
  end
  
  -- Process document blocks
  if results.document_blocks and #results.document_blocks > 0 then
    table.insert(lines, "📚 Document Results:")
    table.insert(lines, "")
    
    for i, block in ipairs(results.document_blocks) do
      local line_num = #lines + 1
      file_map[line_num] = {
        path = block.path,
        start_line = block.start_line,
        end_line = block.end_line
      }
      
      table.insert(lines, string.format("  %d. %s:%d-%d (%.3f)", 
        i, block.path, block.start_line, block.end_line, block.distance))
      
      if block.title then
        table.insert(lines, string.format("     Title: %s", block.title))
      end
      
      -- Show preview
      if block.content then
        local content_lines = vim.split(block.content, "\n")
        local preview_lines = math.min(2, #content_lines)
        
        for j = 1, preview_lines do
          local line = content_lines[j]:gsub("^%s*", "     ")
          if #line > 80 then
            line = line:sub(1, 77) .. "..."
          end
          table.insert(lines, line)
        end
      end
      
      table.insert(lines, "")
    end
  end
  
  -- Process text blocks
  if results.text_blocks and #results.text_blocks > 0 then
    table.insert(lines, "📝 Text Results:")
    table.insert(lines, "")
    
    for i, block in ipairs(results.text_blocks) do
      local line_num = #lines + 1
      file_map[line_num] = {
        path = block.path,
        start_line = block.start_line,
        end_line = block.end_line
      }
      
      table.insert(lines, string.format("  %d. %s:%d-%d (%.3f)", 
        i, block.path, block.start_line, block.end_line, block.distance))
      
      if block.content then
        local content_lines = vim.split(block.content, "\n")
        local preview_lines = math.min(2, #content_lines)
        
        for j = 1, preview_lines do
          local line = content_lines[j]:gsub("^%s*", "     ")
          if #line > 80 then
            line = line:sub(1, 77) .. "..."
          end
          table.insert(lines, line)
        end
      end
      
      table.insert(lines, "")
    end
  end
  
  -- Add beautiful footer
  table.insert(lines, "")
  table.insert(lines, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  table.insert(lines, "")
  table.insert(lines, "🎯 Quick Actions:")
  table.insert(lines, "  • <Enter> - Open file in right panel")
  table.insert(lines, "  • gi - Jump to search input")
  table.insert(lines, "  • gr - Jump to results")
  table.insert(lines, "  • q - Close search panel")
  table.insert(lines, "")
  table.insert(lines, "✨ Found " .. ((results.code_blocks and #results.code_blocks or 0) + 
                                    (results.document_blocks and #results.document_blocks or 0) + 
                                    (results.text_blocks and #results.text_blocks or 0)) .. " results")
  
  -- Store file map globally for opening files
  _G.octocode_file_map = file_map
  
  return lines
end

-- Open result file at specific location
function M.open_result(line)
  local file_map = _G.octocode_file_map
  
  if not file_map then
    vim.notify("No file information available", vim.log.levels.WARN)
    return
  end
  
  -- Find the file info for current line
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local file_info = nil
  
  -- Look backwards from current line to find the nearest file entry
  for i = line_num, 1, -1 do
    if file_map[i] then
      file_info = file_map[i]
      break
    end
  end
  
  if not file_info then
    vim.notify("No file information found for this line", vim.log.levels.WARN)
    return
  end
  
  -- Find the right panel window or create one
  local target_win = nil
  local current_win = vim.api.nvim_get_current_win()
  
  -- Look for a window to the right of current
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= current_win then
      local buf = vim.api.nvim_win_get_buf(win)
      local buftype = vim.bo[buf].buftype
      if buftype == "" then -- Normal file buffer
        target_win = win
        break
      end
    end
  end
  
  -- If no suitable window found, create one
  if not target_win then
    -- Go to the right and create a new window
    vim.cmd("wincmd l")
    if vim.api.nvim_get_current_win() == current_win then
      -- Still in search window, create new split
      vim.cmd("rightbelow vsplit")
    end
    target_win = vim.api.nvim_get_current_win()
  end
  
  -- Switch to target window and open file
  vim.api.nvim_set_current_win(target_win)
  vim.cmd("edit " .. file_info.path)
  
  -- Jump to the specific line
  if file_info.start_line then
    vim.api.nvim_win_set_cursor(0, {file_info.start_line, 0})
    vim.cmd("normal! zz") -- Center the line
  end
  
  vim.notify(string.format("Opened %s at line %d", file_info.path, file_info.start_line))
end

return M