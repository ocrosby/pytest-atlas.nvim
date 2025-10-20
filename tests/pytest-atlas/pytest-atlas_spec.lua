local plugin = require("pytest-atlas")

describe("setup", function()
  it("works with default config", function()
    plugin.setup()
    assert.are.equal("<leader>tt", plugin.config.keymap)
    assert.are.equal(true, plugin.config.enable_keymap)
  end)

  it("works with custom keymap", function()
    plugin.setup({ keymap = "<leader>pt" })
    assert.are.equal("<leader>pt", plugin.config.keymap)
  end)

  it("works with keymap disabled", function()
    plugin.setup({ enable_keymap = false })
    assert.are.equal(false, plugin.config.enable_keymap)
  end)
end)

describe("venv utilities", function()
  local venv_utils = require("pytest-atlas.utils.venv")

  it("finds virtual environments", function()
    local venvs = venv_utils.find_virtual_envs()
    assert.are.equal("table", type(venvs))
  end)

  it("returns empty table when no venvs found", function()
    -- This will likely be empty in test environment
    local venvs = venv_utils.find_virtual_envs()
    assert.are.equal(0, #venvs)
  end)
end)

describe("config utilities", function()
  local config_utils = require("pytest-atlas.utils.config")

  it("loads default env region config", function()
    local config = config_utils.load_env_region_config()
    assert.are.equal("table", type(config))
    assert.are.equal("table", type(config.environments))
  end)

  it("loads cached marker with defaults", function()
    local marker = config_utils.load_cached_marker()
    assert.are.equal("table", type(marker))
    assert.are.equal("string", type(marker.environment))
    assert.are.equal("string", type(marker.region))
  end)
end)
