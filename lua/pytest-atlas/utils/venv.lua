-- lua/pytest-atlas/utils/venv.lua
-- Python virtual environment detection utilities

local M = {}

--- Check if system is Windows
--- @return boolean True if Windows
local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

--- Get activate script path for virtual environment
--- @param venv_path string Virtual environment directory path
--- @return string|nil Activate script path or nil if not found
function M.get_activate_script_path(venv_path)
  local subpath = is_windows() and "/Scripts/activate" or "/bin/activate"
  local activate_path = venv_path .. subpath

  if vim.fn.filereadable(activate_path) == 1 then
    return activate_path
  end
  return nil
end

--- Find all virtual environments in current directory
--- @return table Array of venv paths
function M.find_virtual_envs()
  local cwd = vim.fn.getcwd()
  local entries = vim.fn.readdir(cwd)
  local venvs = {}

  -- Common virtual environment directory names
  local venv_names = { ".venv", "venv", "env", ".env", "virtualenv" }

  for _, entry in ipairs(entries) do
    local dir_path = cwd .. "/" .. entry

    if vim.fn.isdirectory(dir_path) == 1 then
      -- Check if it matches common venv directory names
      local is_venv_dir = false
      for _, venv_name in ipairs(venv_names) do
        if entry == venv_name then
          is_venv_dir = true
          break
        end
      end

      -- If it matches venv name or has activate script, add it
      if is_venv_dir and M.get_activate_script_path(dir_path) then
        table.insert(venvs, dir_path)
      end
    end
  end

  return venvs
end

return M
