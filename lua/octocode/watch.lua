-- Simple octocode watch process management

local M = {}

-- State management
local state = {
  job_id = nil,
  is_running = false,
}

-- Helper function for notifications
local function notify(message, level)
  local config = require("octocode").config
  if not config.silent then
    vim.notify(message, level or vim.log.levels.INFO, { title = "Octocode" })
  end
end

-- Start watch process
function M.start()
  if state.is_running then
    return false
  end
  
  local config = require("octocode").config
  local cmd = { config.command or "octocode", "watch" }
  
  state.job_id = vim.fn.jobstart(cmd, {
    cwd = vim.fn.getcwd(),
    on_exit = function(_, exit_code)
      state.is_running = false
      state.job_id = nil
    end,
  })
  
  if state.job_id > 0 then
    state.is_running = true
    return true
  else
    return false
  end
end

-- Stop watch process
function M.stop()
  if not state.is_running or not state.job_id then
    return false
  end
  
  vim.fn.jobstop(state.job_id)
  state.is_running = false
  state.job_id = nil
  return true
end

-- Toggle watch process
function M.toggle()
  if state.is_running then
    notify("Stopping Octocode indexing...", vim.log.levels.INFO)
    M.stop()
  else
    notify("Starting Octocode indexing...", vim.log.levels.INFO)
    M.start()
  end
end

-- Setup - just start watch on Neovim startup
function M.setup()
  -- Clean up on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if state.is_running then
        M.stop()
      end
    end,
  })
end

return M
