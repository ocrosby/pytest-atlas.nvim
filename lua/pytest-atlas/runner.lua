-- lua/pytest-atlas/runner.lua
-- Pytest execution with environment configuration

local M = {}

local logger = require("pytest-atlas.logger")
local venv_utils = require("pytest-atlas.utils.venv")
local terminal_utils = require("pytest-atlas.utils.terminal")

--- Run pytest with selected configuration
--- @param selection table Test configuration selection
function M.run(selection)
  logger.enter("runner.run", selection)

  if not selection then
    logger.warn("Test picker cancelled - no selection provided")
    vim.notify("Test picker cancelled", vim.log.levels.INFO)
    return
  end

  local env = selection.environment
  local region = selection.region
  local markers = selection.markers
  local open_allure = selection.open_allure

  logger.debug("Parsed selection - env: " .. env .. ", region: " .. region .. ", markers: " .. tostring(markers))

  -- Set environment variables for the session
  logger.debug("Setting environment variables")
  vim.env.TEST_ENVIRONMENT = env
  vim.env.TEST_REGION = region
  vim.env.TEST_MARKERS = markers or ""
  vim.env.TEST_OPEN_ALLURE = open_allure and "true" or "false"

  -- Notify user about the selection
  vim.notify(
    string.format("Running tests in %s (%s) with markers: %s", env, region, markers or "None"),
    vim.log.levels.INFO
  )

  -- Check for uv first
  local has_uv = vim.fn.executable("uv") == 1
  local use_uv = has_uv
  
  -- Check for virtual environment and build pytest command
  logger.debug("Searching for virtual environments")
  local venvs = venv_utils.find_virtual_envs()
  logger.debug("Found " .. #venvs .. " virtual environments: " .. vim.inspect(venvs))

  local python_cmd = "python"
  local pytest_cmd = "pytest"
  local python_prefix = ""

  if use_uv then
    python_prefix = "uv run "
    python_cmd = "uv run python"
    pytest_cmd = "uv run pytest"
    logger.info("Using uv for package management", true)
    vim.notify("Using uv for package management", vim.log.levels.INFO)
  elseif #venvs > 0 then
    local venv = venvs[1]
    python_cmd = venv .. "/bin/python"
    pytest_cmd = venv .. "/bin/pytest"
    logger.info("Using virtual environment: " .. venv, true)
    vim.notify(string.format("Using virtual environment: %s", venv), vim.log.levels.INFO)
  else
    logger.warn("No virtual environment found, using system Python", true)
    vim.notify("No virtual environment found, using system Python", vim.log.levels.WARN)
  end

  -- Build pytest command with environment configuration
  local pytest_args = {
    "--tb=short",
    "-v",
  }

  -- Add markers if specified
  if markers and markers ~= "" then
    table.insert(pytest_args, "-m")
    table.insert(pytest_args, markers)
  end

  if open_allure then
    table.insert(pytest_args, "--alluredir=allure-results")
  end

  -- Run pytest with environment configuration
  local cmd = { pytest_cmd, unpack(pytest_args) }
  local cmd_str = table.concat(cmd, " ")

  vim.notify(string.format("Running: %s", cmd_str), vim.log.levels.INFO)

  -- Prepare environment variables for the terminal
  local terminal_env = {
    TEST_ENVIRONMENT = env,
    TEST_REGION = region,
    TEST_MARKERS = markers or "",
    TEST_OPEN_ALLURE = open_allure and "true" or "false",
  }

  -- Add virtual environment variables if using venv (not needed for uv)
  if not use_uv and #venvs > 0 then
    local venv = venvs[1]
    terminal_env.VIRTUAL_ENV = venv
    terminal_env.PATH = venv .. "/bin:" .. (os.getenv("PATH") or "")
  end

  -- Check if preprocessor.py exists
  local preprocessor_path = "preprocessor.py"
  local has_preprocessor = vim.fn.filereadable(preprocessor_path) == 1

  local actual_command
  if has_preprocessor then
    -- Use preprocessor.py process command
    local python_exe = python_cmd
    local preprocessor_args = { "process", "-e", env, "-r", region }

    if markers and markers ~= "" then
      table.insert(preprocessor_args, "-m")
      table.insert(preprocessor_args, markers)
    end

    actual_command = python_exe .. " " .. preprocessor_path .. " " .. table.concat(preprocessor_args, " ")
  else
    actual_command = cmd_str
  end

  -- Create configuration display for terminal
  local config_display = {
    "=" .. string.rep("=", 60),
    "TEST CONFIGURATION",
    "=" .. string.rep("=", 60),
    "Environment: " .. env,
    "Region: " .. region,
    "Markers: " .. (markers and markers ~= "" and markers or "None"),
    "Allure Report: " .. (open_allure and "Yes" or "No"),
    "Python Env: " .. (use_uv and "uv" or (#venvs > 0 and venvs[1] or "System Python")),
    "Execution Mode: " .. (has_preprocessor and "Preprocessor Script" or "Direct Pytest"),
    "Command: " .. actual_command,
    "=" .. string.rep("=", 60),
    "",
  }

  local enhanced_command
  if open_allure then
    local clean_allure = "rm -rf allure-results"
    local allure_serve_cmd = "allure serve allure-results"
    if use_uv then
      allure_serve_cmd = "(uv run allure serve allure-results 2>/dev/null || allure serve allure-results)"
    elseif #venvs > 0 then
      allure_serve_cmd = "("
        .. venvs[1]
        .. "/bin/allure serve allure-results 2>/dev/null || allure serve allure-results)"
    end

    local config_echo = "printf '%s\\n' "
      .. table.concat(
        vim.tbl_map(function(line)
          return "'" .. line:gsub("'", "'\\''") .. "'"
        end, config_display),
        " "
      )
    
    local allure_check_and_serve = "printf '\\n' && printf '%s\\n' '🔍 Checking for Allure results...' && "
      .. "if [ -d 'allure-results' ] && [ \"$(ls -A allure-results 2>/dev/null)\" ]; then "
      .. "printf '%s\\n' '✅ Allure results found! Serving report...' "
      .. "'Press Ctrl+C or close this terminal to stop the Allure server' '' && "
      .. allure_serve_cmd
      .. " & ALLURE_PID=$!; wait $ALLURE_PID; "
      .. "else "
      .. "printf '%s\\n' '❌ No Allure results found in allure-results/ directory'; "
      .. "fi"
    
    local cleanup_func = "cleanup() { printf '\\n%s\\n' '🧹 Cleaning up Allure server processes...'; "
      .. "jobs -p | xargs -r kill -9 2>/dev/null; "
      .. "pkill -P $$ -f 'allure.*serve' 2>/dev/null; "
      .. "pkill -P $$ -f 'java.*jetty' 2>/dev/null; "
      .. "sleep 0.5; "
      .. "REMAINING=$(pgrep -f 'allure.*serve|java.*jetty' 2>/dev/null); "
      .. "if [ -n \"$REMAINING\" ]; then "
      .. "printf '%s\\n' \"Force killing remaining processes: $REMAINING\"; "
      .. "echo \"$REMAINING\" | xargs -r kill -9 2>/dev/null; "
      .. "fi; "
      .. "printf '%s\\n' '✅ Cleanup complete'; }; "
      .. "trap cleanup EXIT INT TERM"
    
    enhanced_command = cleanup_func
      .. " && rm -rf allure-results"
      .. " && "
      .. config_echo
      .. " && "
      .. actual_command
      .. " && "
      .. allure_check_and_serve
  else
    local config_echo = "printf '%s\\n' "
      .. table.concat(
        vim.tbl_map(function(line)
          return "'" .. line:gsub("'", "'\\''") .. "'"
        end, config_display),
        " "
      )
    enhanced_command = config_echo .. " && " .. actual_command
  end

  -- Check if snacks.terminal is available
  logger.debug("Checking snacks.terminal availability")
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.terminal then
    logger.error("snacks.terminal is not available: " .. tostring(snacks))
    vim.notify("snacks.terminal is required for pytest-atlas.nvim", vim.log.levels.ERROR)
    return
  end
  logger.debug("snacks.terminal is available")

  -- Execute enhanced command in a terminal with environment variables
  logger.debug("Creating terminal window configuration")
  local win_opts = terminal_utils.make_win_opts(open_allure and "Pytest + Allure Server" or "Pytest Test Runner")
  logger.debug("Window options: " .. vim.inspect(win_opts))

  local original_on_buf = win_opts.on_buf
  win_opts.on_buf = function(self)
    logger.debug("Terminal buffer created: " .. self.buf)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(self.buf) then
        vim.bo[self.buf].modifiable = true
        vim.bo[self.buf].readonly = false
        logger.debug("Buffer options set for buf " .. self.buf)
      else
        logger.warn("Terminal buffer " .. self.buf .. " is not valid")
      end
    end)
    
    self:on("BufWipeout", function()
      logger.debug("BufWipeout triggered for terminal buffer " .. self.buf)
      if open_allure then
        logger.info("Cleaning up Allure server processes via BufWipeout")
        vim.fn.jobstart({
          "sh",
          "-c",
          "pkill -9 -f 'allure.*serve' 2>/dev/null; pkill -9 -f 'java.*jetty' 2>/dev/null || true",
        }, {
          detach = true,
          on_exit = function(_, exit_code)
            if exit_code == 0 then
              logger.info("Allure server cleanup successful")
              vim.notify("✅ Allure server stopped", vim.log.levels.INFO)
            else
              logger.debug("Allure cleanup exit code: " .. exit_code)
            end
          end,
        })
      end
    end, { buf = true })
    
    if original_on_buf then
      original_on_buf(self)
    end
  end

  logger.info("Opening terminal with command: " .. enhanced_command)
  local term_ok, terminal = pcall(function()
    return snacks.terminal.open({ "sh", "-c", enhanced_command }, {
      env = terminal_env,
      win = win_opts,
      start_insert = false,
      auto_insert = false,
    })
  end)

  if not term_ok then
    logger.exception("runner.run - terminal.open failed", terminal)
  else
    logger.info("Terminal opened successfully")
    logger.exit("runner.run")
  end
end

return M
