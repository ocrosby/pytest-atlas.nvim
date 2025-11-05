-- plugin/pytest-atlas.lua
-- Plugin commands and autocommands

-- Create user commands
vim.api.nvim_create_user_command("PytestAtlasRun", function()
  require("pytest-atlas").run_tests()
end, { desc = "Run pytest with test picker" })

vim.api.nvim_create_user_command("PytestAtlasStatus", function()
  require("pytest-atlas").show_status()
end, { desc = "Show current test environment status" })

vim.api.nvim_create_user_command("PytestAtlasLog", function()
  require("pytest-atlas").open_log()
end, { desc = "Open pytest-atlas log file" })

vim.api.nvim_create_user_command("PytestAtlasLogTail", function(opts)
  local lines = tonumber(opts.args) or 100
  require("pytest-atlas.logger").open_log_tail(lines)
end, { 
  nargs = "?",
  desc = "Open last N lines of pytest-atlas log (default: 100)" 
})

vim.api.nvim_create_user_command("PytestAtlasClearLog", function()
  require("pytest-atlas").clear_log()
end, { desc = "Clear pytest-atlas log file" })
