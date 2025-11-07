-- lua/pytest-atlas/picker.lua
-- Test picker for environment, region, markers, and Allure selection

local M = {}

local logger = require("pytest-atlas.logger")
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
  logger.enter("picker.show")

  -- Ensure snacks picker is set up
  logger.debug("Checking snacks availability")
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.picker and snacks.picker.setup then
    logger.debug("Snacks picker available")
    -- Check if vim.ui.select has been replaced with snacks picker
    if vim.ui.select ~= snacks.picker.select then
      logger.debug("Picker not initialized, forcing setup")
      -- Picker not initialized yet, force setup
      pcall(snacks.picker.setup)
    end
  else
    logger.warn("Snacks picker not available: " .. tostring(snacks))
  end

  -- Use vim.ui.select which snacks overrides
  -- This is more stable than calling snacks.picker.select directly
  logger.debug("Loading environment configuration")
  local env_region = config_utils.load_env_region_config()
  logger.debug("Environment config: " .. vim.inspect(env_region))

  logger.debug("Loading cached marker configuration")
  local cached = config_utils.load_cached_marker()
  logger.debug("Cached config: " .. vim.inspect(cached))

  local items, lookup = generate_picker_items(env_region, cached)
  logger.debug("Generated picker items: " .. vim.inspect(items))

  -- Validate we have items to show
  if not items or #items == 0 then
    logger.error("No environments found in configuration")
    vim.notify("No environments found in configuration", vim.log.levels.WARN)
    vim.schedule(function()
      callback(nil)
    end)
    return
  end

  -- Step 1: Select environment
  logger.debug("Step 1: Environment selection")
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

  logger.debug("Showing environment picker with items: " .. vim.inspect(reordered_items))
  logger.debug("vim.ui.select function: " .. tostring(vim.ui.select))
  logger.debug("About to call vim.ui.select...")

  -- Add safety wrapper to ensure callback is always called
  local picker_shown = false
  local callback_invoked = false
  vim.schedule(function()
    vim.defer_fn(function()
      if not picker_shown then
        logger.error("Picker was never shown - vim.ui.select may have failed silently")
      end
      if not callback_invoked then
        logger.warn("Picker callback was never invoked after 5 seconds")
      end
    end, 5000)
  end)

  logger.debug("Calling vim.ui.select now...")
  vim.ui.select(reordered_items, {
    prompt = "Select Environment",
  }, function(selected_env)
    callback_invoked = true
    picker_shown = true
    logger.debug("=== ENVIRONMENT PICKER CALLBACK INVOKED ===")
    logger.debug("Environment selected: " .. tostring(selected_env))
    logger.debug("Callback function type: " .. type(callback))
    logger.debug("Selection type: " .. type(selected_env))

    if not selected_env then
      logger.info("Environment selection cancelled")
      callback(nil)
      return
    end

    local env_data = lookup[selected_env]
    if not env_data or not env_data.regions then
      logger.error("Invalid environment selection: " .. tostring(selected_env))
      vim.notify("Invalid environment selection: " .. tostring(selected_env), vim.log.levels.ERROR)
      callback(nil)
      return
    end

    -- Step 2: Select region
    logger.debug("Step 2: Region selection for " .. selected_env)
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

    logger.debug("Showing region picker with items: " .. vim.inspect(reordered_regions))

    vim.ui.select(reordered_regions, {
      prompt = "Select Region for " .. selected_env,
    }, function(selected_region)
      logger.debug("Region selected: " .. tostring(selected_region))

      if not selected_region then
        logger.info("Region selection cancelled")
        callback(nil)
        return
      end

      -- Step 3: Select markers
      logger.debug("Step 3: Marker selection")
      local markers = load_markers()
      logger.debug("Available markers: " .. vim.inspect(markers))

      table.insert(markers, 1, "None")

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

      logger.debug("Showing marker picker with items: " .. vim.inspect(reordered_markers))

      vim.ui.select(reordered_markers, {
        prompt = "Select Test Markers",
      }, function(selected_markers)
        logger.debug("Markers selected: " .. tostring(selected_markers))

        if not selected_markers then
          logger.info("Marker selection cancelled")
          callback(nil)
          return
        end

        if selected_markers == "None" then
          selected_markers = nil
        end

        -- Step 4: Select Allure preference
        logger.debug("Step 4: Allure selection")
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

        logger.debug("Showing allure picker with default: " .. default_allure)

        vim.ui.select(reordered_allure, {
          prompt = "Generate Allure Report?",
        }, function(allure_choice)
          logger.debug("Allure choice: " .. tostring(allure_choice))

          if allure_choice == nil then
            logger.info("Allure selection cancelled")
            callback(nil)
            return
          end

          local open_allure = allure_choice == "Yes, open Allure report"

          -- Save selection to cache
          logger.debug("Saving configuration to cache")
          config_utils.save_cached_marker(selected_env, selected_region, selected_markers, open_allure)

          local final_selection = {
            environment = selected_env,
            region = selected_region,
            markers = selected_markers,
            open_allure = open_allure,
          }

          logger.info("Picker complete, calling callback with: " .. vim.inspect(final_selection))
          logger.exit("picker.show", final_selection)

          callback(final_selection)
        end)
      end)
    end)
  end)
end

return M
