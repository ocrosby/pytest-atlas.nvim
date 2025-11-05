-- lua/pytest-atlas.lua
-- Main module for pytest-atlas.nvim

local logger = require("pytest-atlas.logger")
local picker = require("pytest-atlas.picker")
local runner = require("pytest-atlas.runner")

---@class Config
---@field keymap string|nil Default keymap for test picker (default: <leader>tt)
---@field enable_keymap boolean Whether to enable default keymap (default: true)
---@field debug boolean Enable debug logging (default: false)
local config = {
  keymap = "<leader>tt",
  enable_keymap = true,
  debug = false,
}

---@class PytestAtlas
local M = {}

---@type Config
M.config = config

--- Setup function for configuring the plugin
---@param args Config? User configuration
M.setup = function(args)
  logger.enter("pytest-atlas.setup", args)
  
  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  -- Set log level based on debug flag
  if M.config.debug then
    logger.set_level("DEBUG")
    logger.info("Debug logging enabled", true)
  else
    logger.set_level("INFO")
  end

  -- Register default keymap if enabled
  if M.config.enable_keymap and M.config.keymap then
    logger.debug("Registering keymap: " .. M.config.keymap)
    vim.keymap.set("n", M.config.keymap, M.run_tests, { desc = "Pytest: Run with test picker" })
  end
  
  logger.exit("pytest-atlas.setup")
end

--- Run test picker and execute pytest with selected configuration
M.run_tests = function()
  logger.enter("pytest-atlas.run_tests")
  
  local ok, err = pcall(function()
    picker.show(function(selection)
      logger.debug("Picker callback invoked with selection: " .. vim.inspect(selection))
      runner.run(selection)
    end)
  end)
  
  if not ok then
    logger.exception("pytest-atlas.run_tests", err)
  else
    logger.exit("pytest-atlas.run_tests")
  end
end

--- Show current test environment status
M.show_status = function()
  logger.enter("pytest-atlas.show_status")
  local env = vim.env.TEST_ENVIRONMENT or "qa"
  local region = vim.env.TEST_REGION or "auto"
  vim.notify(string.format("Current test environment: %s (%s)", env, region), vim.log.levels.INFO)
  logger.exit("pytest-atlas.show_status")
end

--- Open pytest-atlas log file
M.open_log = function()
  logger.open_log()
end

--- Clear pytest-atlas log file
M.clear_log = function()
  logger.clear()
end

return M
