-- lua/pytest-atlas.lua
-- Main module for pytest-atlas.nvim

local picker = require("pytest-atlas.picker")
local runner = require("pytest-atlas.runner")

---@class Config
---@field keymap string|nil Default keymap for test picker (default: <leader>tt)
---@field enable_keymap boolean Whether to enable default keymap (default: true)
local config = {
  keymap = "<leader>tt",
  enable_keymap = true,
}

---@class PytestAtlas
local M = {}

---@type Config
M.config = config

--- Setup function for configuring the plugin
---@param args Config? User configuration
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  -- Register default keymap if enabled
  if M.config.enable_keymap and M.config.keymap then
    vim.keymap.set("n", M.config.keymap, M.run_tests, { desc = "Pytest: Run with test picker" })
  end
end

--- Run test picker and execute pytest with selected configuration
M.run_tests = function()
  picker.show(function(selection)
    runner.run(selection)
  end)
end

--- Show current test environment status
M.show_status = function()
  local env = vim.env.TEST_ENVIRONMENT or "qa"
  local region = vim.env.TEST_REGION or "auto"
  vim.notify(string.format("Current test environment: %s (%s)", env, region), vim.log.levels.INFO)
end

return M
