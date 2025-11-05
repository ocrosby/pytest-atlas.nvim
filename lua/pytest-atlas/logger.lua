-- lua/pytest-atlas/logger.lua
-- Logging utility for pytest-atlas debugging

local M = {}

-- Log levels
M.LEVELS = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
}

-- Default log level (set to DEBUG for detailed logging, INFO for normal use)
M.log_level = M.LEVELS.DEBUG

-- Log file path
M.log_file = vim.fn.stdpath("cache") .. "/pytest-atlas.log"

--- Initialize logging
function M.init()
  -- Append to log file (don't clear) to preserve crash logs between sessions
  local file = io.open(M.log_file, "a")
  if file then
    file:write(string.format("\n\n=== Pytest-Atlas Session Started: %s ===\n", os.date("%Y-%m-%d %H:%M:%S")))
    file:close()
  end
end

--- Write log message to file and optionally notify
--- @param level number Log level
--- @param level_name string Level name for display
--- @param message string Log message
--- @param notify boolean Whether to show vim notification
local function log(level, level_name, message, notify)
  if level < M.log_level then
    return
  end

  local timestamp = os.date("%H:%M:%S")
  local log_line = string.format("[%s] [%s] %s\n", timestamp, level_name, message)

  -- Write to file
  local file = io.open(M.log_file, "a")
  if file then
    file:write(log_line)
    file:close()
  end

  -- Show notification if requested
  if notify then
    local vim_level = vim.log.levels.INFO
    if level == M.LEVELS.ERROR then
      vim_level = vim.log.levels.ERROR
    elseif level == M.LEVELS.WARN then
      vim_level = vim.log.levels.WARN
    elseif level == M.LEVELS.DEBUG then
      vim_level = vim.log.levels.DEBUG
    end
    vim.notify("[pytest-atlas] " .. message, vim_level)
  end
end

--- Log debug message
--- @param message string Log message
--- @param notify boolean? Whether to show notification (default: false)
function M.debug(message, notify)
  log(M.LEVELS.DEBUG, "DEBUG", message, notify or false)
end

--- Log info message
--- @param message string Log message
--- @param notify boolean? Whether to show notification (default: false)
function M.info(message, notify)
  log(M.LEVELS.INFO, "INFO", message, notify or false)
end

--- Log warning message
--- @param message string Log message
--- @param notify boolean? Whether to show notification (default: true)
function M.warn(message, notify)
  log(M.LEVELS.WARN, "WARN", message, notify == nil and true or notify)
end

--- Log error message
--- @param message string Log message
--- @param notify boolean? Whether to show notification (default: true)
function M.error(message, notify)
  log(M.LEVELS.ERROR, "ERROR", message, notify == nil and true or notify)
end

--- Log function entry
--- @param func_name string Function name
--- @param args table? Function arguments
function M.enter(func_name, args)
  local msg = string.format("→ ENTER %s", func_name)
  if args then
    msg = msg .. " | args: " .. vim.inspect(args)
  end
  M.debug(msg)
end

--- Log function exit
--- @param func_name string Function name
--- @param result any? Function result
function M.exit(func_name, result)
  local msg = string.format("← EXIT %s", func_name)
  if result ~= nil then
    msg = msg .. " | result: " .. vim.inspect(result)
  end
  M.debug(msg)
end

--- Log exception/error with traceback
--- @param func_name string Function where error occurred
--- @param err string Error message
function M.exception(func_name, err)
  local msg = string.format("✗ EXCEPTION in %s: %s\n%s", func_name, tostring(err), debug.traceback())
  M.error(msg, true)
end

--- Open log file in a new buffer
function M.open_log()
  if vim.fn.filereadable(M.log_file) == 1 then
    vim.cmd("tabnew " .. M.log_file)
    vim.bo.filetype = "log"
    vim.bo.readonly = true
    vim.cmd("normal! G") -- Jump to end of file (most recent logs)
  else
    vim.notify("Log file not found: " .. M.log_file, vim.log.levels.WARN)
  end
end

--- Open log file and show only the last session
function M.open_log_tail(lines)
  lines = lines or 100
  if vim.fn.filereadable(M.log_file) == 1 then
    vim.cmd("tabnew " .. M.log_file)
    vim.bo.filetype = "log"
    vim.bo.readonly = true
    -- Jump to last N lines
    vim.cmd("normal! G")
    if lines > 0 then
      vim.cmd(string.format("normal! %dk", lines))
    end
  else
    vim.notify("Log file not found: " .. M.log_file, vim.log.levels.WARN)
  end
end

--- Clear log file
function M.clear()
  local file = io.open(M.log_file, "w")
  if file then
    file:write(string.format("=== Pytest-Atlas Log Cleared: %s ===\n", os.date("%Y-%m-%d %H:%M:%S")))
    file:close()
  end
  vim.notify("Pytest-atlas log cleared", vim.log.levels.INFO)
end

--- Set log level
--- @param level number|string Log level (number or "DEBUG", "INFO", "WARN", "ERROR")
function M.set_level(level)
  if type(level) == "string" then
    level = M.LEVELS[level:upper()]
  end
  if level then
    M.log_level = level
    M.info(string.format("Log level set to %d", level))
  end
end

-- Initialize on module load
M.init()

return M
