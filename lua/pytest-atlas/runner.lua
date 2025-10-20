-- lua/pytest-atlas/runner.lua
-- Pytest execution with environment configuration

local M = {}

local venv_utils = require("pytest-atlas.utils.venv")
local terminal_utils = require("pytest-atlas.utils.terminal")

--- Run pytest with selected configuration
--- @param selection table Test configuration selection
function M.run(selection)
  if not selection then
    vim.notify("Test picker cancelled", vim.log.levels.INFO)
    return
  end

  local env = selection.environment
  local region = selection.region
  local markers = selection.markers
  local open_allure = selection.open_allure

  -- Set environment variables for the session
  vim.env.TEST_ENVIRONMENT = env
  vim.env.TEST_REGION = region
  vim.env.TEST_MARKERS = markers
  vim.env.TEST_OPEN_ALLURE = open_allure and "true" or "false"

  -- Notify user about the selection
  vim.notify(string.format("Running tests in %s (%s) with markers: %s", env, region, markers), vim.log.levels.INFO)

  -- Check for virtual environment and build pytest command
  local venvs = venv_utils.find_virtual_envs()
  local python_cmd = "python"
  local pytest_cmd = "pytest"

  if #venvs > 0 then
    local venv = venvs[1]
    python_cmd = venv .. "/bin/python"
    pytest_cmd = venv .. "/bin/pytest"
    vim.notify(string.format("Using virtual environment: %s", venv), vim.log.levels.INFO)
  else
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

  -- Add allure report if requested
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
    TEST_MARKERS = markers,
    TEST_OPEN_ALLURE = open_allure and "true" or "false",
  }

  -- Add virtual environment variables if using venv
  if #venvs > 0 then
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
    local python_exe = (#venvs > 0 and venvs[1] .. "/bin/python" or "python")
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
    "Markers: " .. (markers ~= "" and markers or "None"),
    "Allure Report: " .. (open_allure and "Yes" or "No"),
    "Python Env: " .. (#venvs > 0 and venvs[1] or "System Python"),
    "Execution Mode: " .. (has_preprocessor and "Preprocessor Script" or "Direct Pytest"),
    "Command: " .. actual_command,
    "=" .. string.rep("=", 60),
    "",
  }

  -- Create enhanced shell command that conditionally handles allure serving
  local enhanced_command
  if open_allure then
    local allure_serve_cmd = "allure serve allure-results"
    if #venvs > 0 then
      allure_serve_cmd = "("
        .. venvs[1]
        .. "/bin/allure serve allure-results 2>/dev/null || allure serve allure-results)"
    end

    local allure_check_and_serve = table.concat({
      "echo ''",
      "echo '🔍 Checking for Allure results...'",
      "if [ -d 'allure-results' ] && [ \"$(ls -A allure-results 2>/dev/null)\" ]",
      "then",
      "  echo '✅ Allure results found! Serving report...'",
      "  echo 'Press Ctrl+C to stop the Allure server'",
      "  echo ''",
      "  " .. allure_serve_cmd,
      "else",
      "  echo '❌ No Allure results found in allure-results/ directory'",
      "fi",
    }, "; ")

    enhanced_command = table.concat({
      "echo '" .. table.concat(config_display, "\\n") .. "'",
      actual_command,
      allure_check_and_serve,
    }, " && ")
  else
    enhanced_command = "echo '" .. table.concat(config_display, "\\n") .. "' && " .. actual_command
  end

  -- Check if snacks.terminal is available
  local ok, snacks_terminal = pcall(require, "snacks.terminal")
  if not ok then
    vim.notify("snacks.terminal is required for pytest-atlas.nvim", vim.log.levels.ERROR)
    return
  end

  -- Execute enhanced command in a terminal with environment variables
  snacks_terminal.open({ "sh", "-c", enhanced_command }, {
    env = terminal_env,
    win = terminal_utils.make_win_opts(open_allure and "Pytest + Allure Server" or "Pytest Test Runner"),
    start_insert = false,
    auto_insert = false,
    on_open = function(term)
      vim.opt_local.modifiable = true
      vim.opt_local.readonly = false
    end,
  })
end

return M
