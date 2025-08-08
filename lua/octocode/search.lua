-- Search module for octocode CLI integration

local M = {}
local config = require("octocode").config

-- Get file icon based on language/extension
local function get_file_icon(path, language)
  if language then
    local lang_icons = {
      rust = "🦀",
      javascript = "🟨",
      typescript = "🔷", 
      python = "🐍",
      go = "🐹",
      java = "☕",
      cpp = "⚡",
      c = "⚡",
      php = "🐘",
      ruby = "💎",
      bash = "🐚",
      json = "📋",
      yaml = "📄",
      toml = "⚙️",
      css = "🎨",
      html = "🌐",
      markdown = "📝",
      text = "📄"
    }
    return lang_icons[language] or "📁"
  end
  
  -- Fallback to extension-based detection
  local ext = path:match("%.([^%.]+)$")
  if ext then
    local ext_icons = {
      rs = "🦀",
      js = "🟨",
      ts = "🔷",
      py = "🐍",
      go = "🐹",
      java = "☕",
      cpp = "⚡",
      cc = "⚡",
      c = "⚡",
      php = "🐘",
      rb = "💎",
      sh = "🐚",
      json = "📋",
      yaml = "📄",
      yml = "📄",
      toml = "⚙️",
      css = "🎨",
      html = "🌐",
      md = "📝",
      txt = "📄"
    }
    return ext_icons[ext] or "📁"
  end
  
  return "📁"
end

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
  
  -- Handle empty results
  -- For array format: check if array is empty
  -- For object format: check if all sub-arrays are empty
  local is_empty = false
  if type(results) == "table" then
    if results.code_blocks or results.document_blocks or results.text_blocks then
      -- All mode: check if all sub-arrays are empty
      local code_count = results.code_blocks and #results.code_blocks or 0
      local doc_count = results.document_blocks and #results.document_blocks or 0  
      local text_count = results.text_blocks and #results.text_blocks or 0
      is_empty = (code_count + doc_count + text_count) == 0
    else
      -- Array mode: check if array is empty
      is_empty = #results == 0
    end
  end
  
  if is_empty then
    local lines = {
      "No results found for this query.",
      "",
      "Try:",
      "• Different search terms",
      "• Switching search mode (ma/mc/md/mt)",
      "• Broader or more specific queries"
    }
    
    vim.bo[results_buf].modifiable = true
    vim.api.nvim_buf_set_lines(results_buf, 0, -1, false, lines)
    vim.bo[results_buf].modifiable = false
    return
  end
  
  local lines = {}
  local file_map = {} -- Map line numbers to file info
  
  -- Detect format: array (mode-specific) vs object (all mode)
  -- All mode has: {code_blocks: [...], document_blocks: [...], text_blocks: [...]}
  -- Mode-specific has: [{path: "...", content: "..."}, ...] or [] (empty array)
  local is_array_format = type(results) == "table" and not (results.code_blocks or results.document_blocks or results.text_blocks)
  
  if is_array_format then
    -- Handle mode-specific array format: [{"path": "...", "content": "...", ...}, ...]
    for i, block in ipairs(results) do
      local line_num = #lines + 1
      file_map[line_num] = {
        path = block.path,
        start_line = block.start_line,
        end_line = block.end_line
      }
      
      -- Format result entry with result number and proper icon
      local file_icon = get_file_icon(block.path, block.language)
      table.insert(lines, string.format("%d. %s %s:", i, file_icon, block.path))
      
      -- Show content with actual line numbers from file
      if block.content then
        local content_lines = vim.split(block.content, "\n")
        local start_line = block.start_line or 1
        
        for j, content_line in ipairs(content_lines) do
          if j <= 5 then -- Show first 5 lines
            local actual_line_num = start_line + j - 1
            local formatted_line = string.format("  %d: %s", actual_line_num, content_line)
            if #formatted_line > 80 then
              formatted_line = formatted_line:sub(1, 77) .. "..."
            end
            table.insert(lines, formatted_line)
          end
        end
      end
      
      table.insert(lines, "")
    end
  else
    -- Handle "all" mode object format: {code_blocks: [...], document_blocks: [...], text_blocks: [...]}
    -- All block types have the same structure: {path, content, start_line, end_line, language, etc.}
    local result_counter = 0
    
    -- Process code blocks
    if results.code_blocks and #results.code_blocks > 0 then
      for i, block in ipairs(results.code_blocks) do
        result_counter = result_counter + 1
        local line_num = #lines + 1
        file_map[line_num] = {
          path = block.path,
          start_line = block.start_line,
          end_line = block.end_line
        }
        
        -- Format result entry with result number and proper icon
        local file_icon = get_file_icon(block.path, block.language)
        table.insert(lines, string.format("%d. %s %s:", result_counter, file_icon, block.path))
        
        -- Show content with actual line numbers from file
        if block.content then
          local content_lines = vim.split(block.content, "\n")
          local start_line = block.start_line or 1
          
          for j, content_line in ipairs(content_lines) do
            if j <= 5 then -- Show first 5 lines
              local actual_line_num = start_line + j - 1
              local formatted_line = string.format("  %d: %s", actual_line_num, content_line)
              if #formatted_line > 80 then
                formatted_line = formatted_line:sub(1, 77) .. "..."
              end
              table.insert(lines, formatted_line)
            end
          end
        end
        
        table.insert(lines, "")
      end
    end
    
    -- Process document blocks (same structure as code_blocks)
    if results.document_blocks and #results.document_blocks > 0 then
      for i, block in ipairs(results.document_blocks) do
        result_counter = result_counter + 1
        local line_num = #lines + 1
        file_map[line_num] = {
          path = block.path,
          start_line = block.start_line,
          end_line = block.end_line
        }
        
        -- Format document entry with result number and proper icon
        local file_icon = get_file_icon(block.path, block.language)
        table.insert(lines, string.format("%d. %s %s:", result_counter, file_icon, block.path))
        
        -- Show document content with line numbers (same as code)
        if block.content then
          local content_lines = vim.split(block.content, "\n")
          local start_line = block.start_line or 1
          
          for j, content_line in ipairs(content_lines) do
            if j <= 3 then -- Show first 3 lines for docs
              local actual_line_num = start_line + j - 1
              local formatted_line = string.format("  %d: %s", actual_line_num, content_line)
              if #formatted_line > 80 then
                formatted_line = formatted_line:sub(1, 77) .. "..."
              end
              table.insert(lines, formatted_line)
            end
          end
        end
        
        table.insert(lines, "")
      end
    end
    
    -- Process text blocks (same structure as code_blocks)
    if results.text_blocks and #results.text_blocks > 0 then
      for i, block in ipairs(results.text_blocks) do
        result_counter = result_counter + 1
        local line_num = #lines + 1
        file_map[line_num] = {
          path = block.path,
          start_line = block.start_line,
          end_line = block.end_line
        }
        
        -- Format text entry with result number and proper icon
        local file_icon = get_file_icon(block.path, block.language)
        table.insert(lines, string.format("%d. %s %s:", result_counter, file_icon, block.path))
        
        -- Show text content with line numbers (same structure as code)
        if block.content then
          local content_lines = vim.split(block.content, "\n")
          local start_line = block.start_line or 1
          
          for j, content_line in ipairs(content_lines) do
            if j <= 2 then -- Show first 2 lines for text
              local actual_line_num = start_line + j - 1
              local formatted_line = string.format("  %d: %s", actual_line_num, content_line)
              if #formatted_line > 80 then
                formatted_line = formatted_line:sub(1, 77) .. "..."
              end
              table.insert(lines, formatted_line)
            end
          end
        end
        
        table.insert(lines, "")
      end
    end
  end
  
  -- Handle empty results
  if #lines == 0 then
    table.insert(lines, "No results found for this query.")
    table.insert(lines, "")
    table.insert(lines, "Try:")
    table.insert(lines, "• Different search terms")
    table.insert(lines, "• Switching search mode (ma/mc/md/mt)")
    table.insert(lines, "• Broader or more specific queries")
  else
    -- Add footer with instructions only if we have results
    table.insert(lines, "")
    table.insert(lines, "Press <Enter> on a result to open the file")
    table.insert(lines, "Press <Esc> to close")
  end
  
  -- Store file map for navigation (both buffer and global for reliability)
  vim.b[results_buf].octocode_file_map = file_map
  _G.octocode_file_map = file_map
  
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
          local results_lines, file_map = M.parse_results_for_single_window(json_str)
          
          -- Store file_map globally and in the UI buffer for file opening
          local ui_buf = _G.octocode_search_buf or vim.api.nvim_get_current_buf()
          if file_map then
            -- Create display-line-to-result mapping accounting for UI header offset
            local display_file_map = {}
            local results_start_line = 9  -- UI header takes 8 lines, results start at line 9
            
            -- Map each file_map entry to its actual display line number
            for result_line, file_info in pairs(file_map) do
              local display_line = results_start_line + result_line - 1
              display_file_map[display_line] = file_info
            end
            
            _G.octocode_file_map = display_file_map
            vim.b[ui_buf].octocode_file_map = display_file_map
          end
          
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
  
  -- Handle empty results
  -- For array format: check if array is empty
  -- For object format: check if all sub-arrays are empty
  local is_empty = false
  if type(results) == "table" then
    if results.code_blocks or results.document_blocks or results.text_blocks then
      -- All mode: check if all sub-arrays are empty
      local code_count = results.code_blocks and #results.code_blocks or 0
      local doc_count = results.document_blocks and #results.document_blocks or 0  
      local text_count = results.text_blocks and #results.text_blocks or 0
      is_empty = (code_count + doc_count + text_count) == 0
    else
      -- Array mode: check if array is empty
      is_empty = #results == 0
    end
  end
  
  if is_empty then
    return {
      "No results found for this query.",
      "",
      "Try:",
      "• Different search terms",
      "• Switching search mode (ma/mc/md/mt)",
      "• Broader or more specific queries"
    }
  end
  
  local lines = {}
  local file_map = {} -- Store file info for opening
  
  -- Detect format: array (mode-specific) vs object (all mode)
  -- All mode has: {code_blocks: [...], document_blocks: [...], text_blocks: [...]}
  -- Mode-specific has: [{path: "...", content: "..."}, ...] or [] (empty array)
  local is_array_format = type(results) == "table" and not (results.code_blocks or results.document_blocks or results.text_blocks)
  
  if is_array_format then
    -- Handle mode-specific array format: [{"path": "...", "content": "...", ...}, ...]
    for i, block in ipairs(results) do
      local header_line_num = #lines + 1
      
      -- Store file info for header line
      file_map[header_line_num] = {
        path = block.path,
        start_line = block.start_line,
        end_line = block.end_line
      }
      
      -- Format result entry with result number and proper icon
      local file_icon = get_file_icon(block.path, block.language)
      table.insert(lines, string.format("%d. %s %s:", i, file_icon, block.path))
      
      -- Show content with actual line numbers from file
      if block.content then
        local content_lines = vim.split(block.content, "\n")
        local start_line = block.start_line or 1
        
        for j, content_line in ipairs(content_lines) do
          if j <= 5 then -- Show first 5 lines
            local actual_line_num = start_line + j - 1
            local formatted_line = string.format("  %d: %s", actual_line_num, content_line)
            if #formatted_line > 80 then
              formatted_line = formatted_line:sub(1, 77) .. "..."
            end
            table.insert(lines, formatted_line)
            
            -- Store file info for each content line too (for direct navigation)
            local content_line_num = #lines
            file_map[content_line_num] = {
              path = block.path,
              start_line = actual_line_num,
              end_line = block.end_line,
              is_content_line = true
            }
          end
        end
      end
      
      table.insert(lines, "")
    end
  else
    -- Handle "all" mode object format: {code_blocks: [...], document_blocks: [...], text_blocks: [...]}
    -- All block types have the same structure: {path, content, start_line, end_line, language, etc.}
    local result_counter = 0
    
    -- Process code blocks
    if results.code_blocks and #results.code_blocks > 0 then
      for i, block in ipairs(results.code_blocks) do
        result_counter = result_counter + 1
        local header_line_num = #lines + 1
        
        -- Store file info for header line
        file_map[header_line_num] = {
          path = block.path,
          start_line = block.start_line,
          end_line = block.end_line
        }
        
        -- Format code entry with result number and proper icon
        local file_icon = get_file_icon(block.path, block.language)
        table.insert(lines, string.format("%d. %s %s:", result_counter, file_icon, block.path))
        
        -- Show code lines with actual line numbers from file
        if block.content then
          local content_lines = vim.split(block.content, "\n")
          local start_line = block.start_line or 1
          
          for j, content_line in ipairs(content_lines) do
            if j <= 5 then -- Show first 5 lines
              local actual_line_num = start_line + j - 1
              local formatted_line = string.format("  %d: %s", actual_line_num, content_line)
              if #formatted_line > 80 then
                formatted_line = formatted_line:sub(1, 77) .. "..."
              end
              table.insert(lines, formatted_line)
              
              -- Store file info for each content line too (for direct navigation)
              local content_line_num = #lines
              file_map[content_line_num] = {
                path = block.path,
                start_line = actual_line_num,
                end_line = block.end_line,
                is_content_line = true
              }
            end
          end
        end
        
        table.insert(lines, "")
      end
    end
    
    -- Process document blocks (same structure as code_blocks)
    if results.document_blocks and #results.document_blocks > 0 then
      for i, block in ipairs(results.document_blocks) do
        result_counter = result_counter + 1
        local header_line_num = #lines + 1
        
        -- Store file info for header line
        file_map[header_line_num] = {
          path = block.path,
          start_line = block.start_line,
          end_line = block.end_line
        }
        
        -- Format document entry with result number and proper icon
        local file_icon = get_file_icon(block.path, block.language)
        table.insert(lines, string.format("%d. %s %s:", result_counter, file_icon, block.path))
        
        -- Show document content with line numbers (same as code)
        if block.content then
          local content_lines = vim.split(block.content, "\n")
          local start_line = block.start_line or 1
          
          for j, content_line in ipairs(content_lines) do
            if j <= 3 then -- Show first 3 lines for docs
              local actual_line_num = start_line + j - 1
              local formatted_line = string.format("  %d: %s", actual_line_num, content_line)
              if #formatted_line > 80 then
                formatted_line = formatted_line:sub(1, 77) .. "..."
              end
              table.insert(lines, formatted_line)
              
              -- Store file info for each content line too (for direct navigation)
              local content_line_num = #lines
              file_map[content_line_num] = {
                path = block.path,
                start_line = actual_line_num,
                end_line = block.end_line,
                is_content_line = true
              }
            end
          end
        end
        
        table.insert(lines, "")
      end
    end
    
    -- Process text blocks (same structure as code_blocks)
    if results.text_blocks and #results.text_blocks > 0 then
      for i, block in ipairs(results.text_blocks) do
        result_counter = result_counter + 1
        local header_line_num = #lines + 1
        
        -- Store file info for header line
        file_map[header_line_num] = {
          path = block.path,
          start_line = block.start_line,
          end_line = block.end_line
        }
        
        -- Format text entry with result number and proper icon
        local file_icon = get_file_icon(block.path, block.language)
        table.insert(lines, string.format("%d. %s %s:", result_counter, file_icon, block.path))
        
        -- Show text content with line numbers (same structure as code)
        if block.content then
          local content_lines = vim.split(block.content, "\n")
          local start_line = block.start_line or 1
          
          for j, content_line in ipairs(content_lines) do
            if j <= 2 then -- Show first 2 lines for text
              local actual_line_num = start_line + j - 1
              local formatted_line = string.format("  %d: %s", actual_line_num, content_line)
              if #formatted_line > 80 then
                formatted_line = formatted_line:sub(1, 77) .. "..."
              end
              table.insert(lines, formatted_line)
              
              -- Store file info for each content line too (for direct navigation)
              local content_line_num = #lines
              file_map[content_line_num] = {
                path = block.path,
                start_line = actual_line_num,
                end_line = block.end_line,
                is_content_line = true
              }
            end
          end
        end
        
        table.insert(lines, "")
      end
    end
  end
  
  -- Store file_map for navigation and return both lines and file_map
  return lines, file_map
end

-- Open result file at specific location
function M.open_result(line)
  -- Get current line number
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  
  -- Try to get file_map
  local file_map = _G.octocode_file_map
  if not file_map then
    local current_buf = vim.api.nvim_get_current_buf()
    file_map = vim.b[current_buf].octocode_file_map
  end
  
  if not file_map then
    vim.notify("❌ No file information available. Run a search first.", vim.log.levels.ERROR)
    return
  end
  
  -- Direct line mapping - check if current line has file info
  local file_info = file_map[line_num]
  if not file_info or not file_info.path then
    -- Look backwards to find nearest file entry
    for i = line_num - 1, 1, -1 do
      if file_map[i] and file_map[i].path then
        file_info = file_map[i]
        break
      end
    end
  end
  
  if not file_info or not file_info.path then
    vim.notify("❌ No file found for this line. Click on a result entry.", vim.log.levels.WARN)
    return
  end
  
  -- Validate file exists
  if not vim.fn.filereadable(file_info.path) then
    vim.notify(string.format("❌ File not found: %s", file_info.path), vim.log.levels.ERROR)
    return
  end
  
  -- Find or create target window
  local target_win = nil
  local current_win = vim.api.nvim_get_current_win()
  
  -- Look for existing file window
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= current_win then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "" then
        target_win = win
        break
      end
    end
  end
  
  -- Create new window if needed
  if not target_win then
    vim.cmd("wincmd l")
    if vim.api.nvim_get_current_win() == current_win then
      vim.cmd("rightbelow vsplit")
    end
    target_win = vim.api.nvim_get_current_win()
  end
  
  -- Switch to target window and open file
  vim.api.nvim_set_current_win(target_win)
  vim.cmd("edit " .. vim.fn.fnameescape(file_info.path))
  
  -- Jump to line if specified
  local target_line = file_info.start_line or 1
  if target_line > 0 then
    local total_lines = vim.api.nvim_buf_line_count(0)
    if target_line <= total_lines then
      vim.api.nvim_win_set_cursor(0, {target_line, 0})
      vim.cmd("normal! zz")
    end
  end
  
  vim.notify(string.format("📂 Opened %s at line %d", vim.fn.fnamemodify(file_info.path, ":t"), target_line), vim.log.levels.INFO)
end

return M