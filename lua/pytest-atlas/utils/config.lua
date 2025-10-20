-- lua/pytest-atlas/utils/config.lua
-- Configuration loading utilities

local M = {}

--- Parse JSON configuration file
--- @param path string File path
--- @return table|nil Parsed configuration or nil on failure
local function parse_json_config(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()

  local ok, parsed = pcall(vim.json.decode, content)
  if not ok then
    return nil
  end

  return parsed
end

--- Load environment and region configuration
--- @return table Configuration with environments and regions
function M.load_env_region_config()
  local file_path = "environments.json"

  -- Default fallback configuration
  local fallback = {
    environments = {
      qa = { "auto", "use1" },
      fastly = { "auto" },
      prod = { "auto", "use1", "usw2", "euw1", "apse1" },
    },
  }

  if vim.fn.filereadable(file_path) ~= 1 then
    return fallback
  end

  local config = parse_json_config(file_path)
  return config or fallback
end

--- Load cached marker configuration
--- @return table Cached marker configuration
function M.load_cached_marker()
  local cache_file = vim.fn.stdpath("cache") .. "/pytest_atlas_marker.json"
  local config = parse_json_config(cache_file)

  return config or {
    environment = "qa",
    region = "auto",
    markers = "bdd",
    open_allure = false,
  }
end

--- Save complete test picker configuration to cache
--- @param env string Environment name
--- @param region string Region name
--- @param markers string|table Selected markers
--- @param open_allure boolean Allure preference
function M.save_cached_marker(env, region, markers, open_allure)
  local cache_file = vim.fn.stdpath("cache") .. "/pytest_atlas_marker.json"
  local config = {
    environment = env,
    region = region,
    markers = markers,
    open_allure = open_allure,
    timestamp = os.time(),
  }

  local ok = pcall(function()
    local file = io.open(cache_file, "w")
    if file then
      file:write(vim.json.encode(config))
      file:close()
    end
  end)

  if not ok then
    vim.notify("Failed to save pytest-atlas cache", vim.log.levels.WARN)
  end
end

--- Parse pytest.ini file to extract markers
--- @param pytest_ini_path string Path to pytest.ini file
--- @return table|nil Array of marker names
function M.load_pytest_markers(pytest_ini_path)
  if vim.fn.filereadable(pytest_ini_path) ~= 1 then
    return nil
  end

  local file = io.open(pytest_ini_path, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()

  local lines = vim.split(content, "\n")
  local markers = {}
  local in_markers_section = false

  for _, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")

    -- Check if we're entering the markers section
    if trimmed:match("^markers%s*=") then
      in_markers_section = true
      local markers_line = trimmed:match("^markers%s*=%s*(.+)")
      if markers_line then
        for marker in markers_line:gmatch("([^%s,]+)") do
          if marker ~= "" then
            table.insert(markers, marker)
          end
        end
      end
      goto continue
    end

    -- If we're in markers section, continue parsing
    if in_markers_section then
      -- Stop if we hit a new section
      if trimmed:match("^%[") then
        break
      end

      -- Skip empty lines and comments
      if trimmed == "" or trimmed:match("^#") then
        goto continue
      end

      -- Extract marker name
      local marker = trimmed:match("^([^:]+)")
      if marker then
        marker = marker:match("^%s*(.-)%s*$")
        if marker ~= "" then
          table.insert(markers, marker)
        end
      end
    end

    ::continue::
  end

  return #markers > 0 and markers or nil
end

return M
