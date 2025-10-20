-- plugin/pytest-atlas.lua
-- Plugin commands and autocommands

-- Create user commands
vim.api.nvim_create_user_command("PytestAtlasRun", function()
  require("pytest-atlas").run_tests()
end, { desc = "Run pytest with test picker" })

vim.api.nvim_create_user_command("PytestAtlasStatus", function()
  require("pytest-atlas").show_status()
end, { desc = "Show current test environment status" })
