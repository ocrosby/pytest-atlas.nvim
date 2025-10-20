-- lua/pytest-atlas/picker.lua
-- Test picker for environment, region, markers, and Allure selection

local M = {}

local config_utils = require("pytest-atlas.utils.config")
local venv_utils = require("pytest-atlas.utils.venv")
local terminal_utils = require("pytest-atlas.utils.terminal")

--- Generate picker items from configuration
--- @param env_region table Environment and region configuration
--- @param marker table Cached marker configuration
--- @return table, table Picker items (strings) and lookup table
local function generate_picker_items(env_region, marker)
  local items = {}
  local lookup = {}

  -- Define the correct environment order
  local env_order = { "qa", "fastly", "prod" }

  if env_region.environments then
    for _, env_name in ipairs(env_order) do
      local regions = env_region.environments[env_name]
      if regions then
        table.insert(items, env_name)
        lookup[env_name] = {
          environment = env_name,
          regions = regions,
          type = "environment",
        }
      end
    end
  end

  return items, lookup
end

--- Load markers from pytest.ini with fallback to defaults
--- @return table Available markers
local function load_markers()
  local markers = config_utils.load_pytest_markers("pytest.ini")

  if markers then
    return markers
  else
    return {
      "bdd",
      "unit",
      "functional",
      "smoke",
      "critical",
      "performance",
      "regression",
      "integration",
      "api",
      "ui",
      "slow",
    }
  end
end

--- Test picker for environment, region, markers, and Allure selection
--- @param callback function Callback function receiving selection or nil
function M.show(callback)
  -- Check if snacks.picker is available
  local ok, picker = pcall(require, "snacks.picker")
  if not ok then
    vim.notify("snacks.picker is required for pytest-atlas.nvim", vim.log.levels.ERROR)
    callback(nil)
    return
  end

  local env_region = config_utils.load_env_region_config()
  local cached = config_utils.load_cached_marker()
  local items, lookup = generate_picker_items(env_region, cached)

  -- Step 1: Select environment
  local default_env = cached.environment
  local reordered_items = {}
  if default_env then
    table.insert(reordered_items, default_env)
    for _, item in ipairs(items) do
      if item ~= default_env then
        table.insert(reordered_items, item)
      end
    end
  else
    reordered_items = items
  end

  picker.select(reordered_items, {
    prompt = "Select Environment",
  }, function(selected_env)
    if not selected_env then
      callback(nil)
      return
    end

    local env_data = lookup[selected_env]
    if not env_data or not env_data.regions then
      callback(nil)
      return
    end

    -- Step 2: Select region
    local default_region = (selected_env == cached.environment) and cached.region or nil
    local reordered_regions = {}
    if default_region then
      table.insert(reordered_regions, default_region)
      for _, region in ipairs(env_data.regions) do
        if region ~= default_region then
          table.insert(reordered_regions, region)
        end
      end
    else
      reordered_regions = env_data.regions
    end

    picker.select(reordered_regions, {
      prompt = "Select Region for " .. selected_env,
    }, function(selected_region)
      if not selected_region then
        callback(nil)
        return
      end

      -- Step 3: Select markers
      local markers = load_markers()
      local default_marker = cached.markers
      local marker_exists = false
      for _, marker in ipairs(markers) do
        if marker == default_marker then
          marker_exists = true
          break
        end
      end

      if not marker_exists then
        default_marker = nil
      end

      local reordered_markers = {}
      if default_marker then
        table.insert(reordered_markers, default_marker)
        for _, marker in ipairs(markers) do
          if marker ~= default_marker then
            table.insert(reordered_markers, marker)
          end
        end
      else
        reordered_markers = markers
      end

      picker.select(reordered_markers, {
        prompt = "Select Test Markers",
      }, function(selected_markers)
        if not selected_markers then
          callback(nil)
          return
        end

        -- Step 4: Select Allure preference
        local allure_options = {
          "Yes, open Allure report",
          "No, skip Allure report",
        }
        local default_allure = cached.open_allure and "Yes, open Allure report" or "No, skip Allure report"
        local reordered_allure = {}
        if default_allure then
          table.insert(reordered_allure, default_allure)
          for _, option in ipairs(allure_options) do
            if option ~= default_allure then
              table.insert(reordered_allure, option)
            end
          end
        else
          reordered_allure = allure_options
        end

        picker.select(reordered_allure, {
          prompt = "Generate Allure Report?",
        }, function(allure_choice)
          if allure_choice == nil then
            callback(nil)
            return
          end

          local open_allure = allure_choice == "Yes, open Allure report"

          -- Save selection to cache
          config_utils.save_cached_marker(selected_env, selected_region, selected_markers, open_allure)

          callback({
            environment = selected_env,
            region = selected_region,
            markers = selected_markers,
            open_allure = open_allure,
          })
        end)
      end)
    end)
  end)
end

return M
