-- lua/pytest-atlas/utils/terminal.lua
-- Terminal window configuration utilities

local M = {}

--- Create window options for terminal
--- @param title string Window title
--- @return table Window configuration
function M.make_win_opts(title)
  return {
    relative = "editor",
    position = "float",
    width = 0.9,
    height = 0.85,
    border = "rounded",
    title = title or " Pytest Runner ",
    title_pos = "center",
  }
end

return M
