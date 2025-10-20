# pytest-atlas.nvim

A Neovim plugin that maps your pytest-bdd universe. Seamlessly select environments, regions, and markers, then launch tests with a single command.

## ✨ Features

- 🎯 **Interactive Test Picker**: Select environment, region, and markers through an intuitive picker interface
- 🐍 **Virtual Environment Detection**: Automatically detects and uses Python virtual environments
- 📊 **Allure Report Integration**: Optional Allure report generation and serving
- 💾 **Smart Caching**: Remembers your last test configuration
- 🔧 **Preprocessor Support**: Works with custom preprocessor.py scripts
- ⚙️ **Highly Configurable**: Customize keymaps and behavior to your needs

## 📦 Requirements

- Neovim >= 0.9.0
- [snacks.nvim](https://github.com/folke/snacks.nvim) - For picker UI and terminal
- Python virtual environment (optional but recommended)
- pytest (for running tests)
- allure-commandline (optional, for Allure reports)

## 📥 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ocrosby/pytest-atlas.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  config = function()
    require("pytest-atlas").setup({
      keymap = "<leader>tt", -- Default keymap
      enable_keymap = true,  -- Enable default keymap
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "ocrosby/pytest-atlas.nvim",
  requires = {
    "folke/snacks.nvim",
  },
  config = function()
    require("pytest-atlas").setup()
  end,
}
```

## 🚀 Usage

### Default Keymap

Press `<leader>tt` (default) to open the test picker and:
1. Select your target environment (qa, fastly, prod)
2. Choose the region (auto, use1, usw2, etc.)
3. Pick test markers (bdd, unit, functional, etc.)
4. Decide whether to generate an Allure report

### Commands

- `:PytestAtlasRun` - Open the test picker and run tests
- `:PytestAtlasStatus` - Show current test environment status

### Programmatic Usage

```lua
-- Run test picker
require("pytest-atlas").run_tests()

-- Show environment status
require("pytest-atlas").show_status()
```

## ⚙️ Configuration

### Default Configuration

```lua
require("pytest-atlas").setup({
  keymap = "<leader>tt",  -- Keymap for test picker
  enable_keymap = true,   -- Enable default keymap
})
```

### Custom Keymap

```lua
require("pytest-atlas").setup({
  keymap = "<leader>pt",  -- Custom keymap
})
```

### Disable Default Keymap

```lua
require("pytest-atlas").setup({
  enable_keymap = false,  -- Disable automatic keymap registration
})

-- Register your own keymap
vim.keymap.set("n", "<leader>test", require("pytest-atlas").run_tests)
```

## 📁 Project Configuration

### environments.json

Create an `environments.json` file in your project root to define available environments and regions:

```json
{
  "environments": {
    "qa": ["auto", "use1"],
    "fastly": ["auto"],
    "prod": ["auto", "use1", "usw2", "euw1", "apse1"]
  }
}
```

If not present, defaults to:
- **qa**: auto, use1
- **fastly**: auto  
- **prod**: auto, use1, usw2, euw1, apse1

### pytest.ini

Define your test markers in `pytest.ini`:

```ini
[pytest]
markers =
    bdd: BDD tests
    unit: Unit tests
    functional: Functional tests
    smoke: Smoke tests
    critical: Critical path tests
```

The plugin will automatically parse and present these markers in the picker.

### preprocessor.py (Optional)

If you have a `preprocessor.py` script in your project root, pytest-atlas will use it instead of directly calling pytest:

```python
import click

@click.command()
@click.option("-e", "--environment", required=True)
@click.option("-r", "--region", required=True)
@click.option("-m", "--markers", default="bdd")
def process(environment, region, markers):
    # Your preprocessing logic here
    pass
```

## 🐍 Virtual Environment Detection

pytest-atlas automatically detects Python virtual environments in your project:

- `.venv/` (preferred)
- `venv/`
- `env/`
- `.env/`
- `virtualenv/`

If found, it will use the virtual environment's Python and pytest executables.

## 📊 Allure Reports

When you select "Yes, open Allure report" in the picker:

1. Tests run with `--alluredir=allure-results`
2. After tests complete, Allure server starts automatically if results exist
3. Access the report at `http://localhost` (default Allure port)
4. Press `Ctrl+C` in the terminal to stop the Allure server

## 🧪 Testing

Run tests with:

```bash
make test
```

Or manually:

```bash
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

This plugin extracts and enhances pytest test-running functionality from [yoda.nvim](https://github.com/jedi-knights/yoda.nvim), making it available as a standalone, reusable plugin.
