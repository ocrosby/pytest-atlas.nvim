# Pytest-Atlas Logging Guide

## Overview

Pytest-atlas includes comprehensive logging to help debug issues during test execution. All log messages are written to a log file and can optionally be displayed as notifications.

## Log File Location

```
~/.cache/nvim/pytest-atlas.log
```

## Enabling Debug Logging

Debug logging is enabled by default in your configuration:

```lua
-- lua/plugins/testing.lua
pytest_atlas.setup({
  keymap = "<leader>tt",
  enable_keymap = true,
  debug = true, -- Enable debug logging
})
```

Set `debug = false` to reduce logging verbosity (only INFO, WARN, ERROR).

## Viewing Logs

### Method 1: Keymap (Recommended)

```
<leader>tL    - Open pytest-atlas log in a new tab
<leader>tX    - Clear the log file
```

### Method 2: Commands

```vim
:PytestAtlasLog         " Open log file
:PytestAtlasClearLog    " Clear log file
```

### Method 3: Manual

```bash
tail -f ~/.cache/nvim/pytest-atlas.log
```

Or open directly in Neovim:

```vim
:tabnew ~/.cache/nvim/pytest-atlas.log
```

## Log Levels

The logger supports four log levels:

| Level | Description | Shown in Notifications |
|-------|-------------|----------------------|
| DEBUG | Detailed trace information | No |
| INFO  | General informational messages | No (unless explicitly requested) |
| WARN  | Warning messages | Yes (by default) |
| ERROR | Error messages with stack traces | Yes (by default) |

## What Gets Logged

### 1. Function Entry/Exit

Every major function logs when it's entered and exited:

```
[13:45:22] [DEBUG] → ENTER pytest-atlas.run_tests
[13:45:24] [DEBUG] ← EXIT pytest-atlas.run_tests
```

### 2. Configuration Loading

```
[13:45:22] [DEBUG] Loading environment configuration
[13:45:22] [DEBUG] Environment config: { environments = { ... } }
[13:45:22] [DEBUG] Loading cached marker configuration
[13:45:22] [DEBUG] Cached config: { environment = "qa", ... }
```

### 3. Picker Flow

Each step of the multi-step picker is logged:

```
[13:45:22] [DEBUG] Step 1: Environment selection
[13:45:22] [DEBUG] Showing environment picker with items: { "qa", "fastly", "prod" }
[13:45:23] [DEBUG] Environment selected: qa
[13:45:23] [DEBUG] Step 2: Region selection for qa
[13:45:24] [DEBUG] Region selected: auto
[13:45:24] [DEBUG] Step 3: Marker selection
[13:45:25] [DEBUG] Markers selected: bdd
[13:45:25] [DEBUG] Step 4: Allure selection
[13:45:26] [DEBUG] Allure choice: No, skip Allure report
[13:45:26] [DEBUG] Saving configuration to cache
[13:45:26] [INFO] Picker complete, calling callback with: { environment = "qa", ... }
```

### 4. Virtual Environment Detection

```
[13:45:26] [DEBUG] Searching for virtual environments
[13:45:26] [DEBUG] Found 1 virtual environments: { "/path/to/.venv" }
[13:45:26] [INFO] Using virtual environment: /path/to/.venv
```

### 5. Terminal Creation

```
[13:45:26] [DEBUG] Checking snacks.terminal availability
[13:45:26] [DEBUG] snacks.terminal is available
[13:45:26] [DEBUG] Creating terminal window configuration
[13:45:26] [DEBUG] Window options: { position = "float", width = 0.9, ... }
[13:45:26] [INFO] Opening terminal with command: sh -c echo '...' && pytest ...
[13:45:26] [DEBUG] Terminal buffer created: 42
[13:45:26] [DEBUG] Buffer options set for buf 42
[13:45:26] [INFO] Terminal opened successfully
```

### 6. Errors and Exceptions

When errors occur, full stack traces are logged:

```
[13:45:26] [ERROR] ✗ EXCEPTION in runner.run: attempt to index nil value
stack traceback:
    lua/pytest-atlas/runner.lua:156: in function 'run'
    lua/pytest-atlas.lua:34: in function 'run_tests'
```

## Debugging Workflow

### 1. Clear the log before testing

```
<leader>tX
```

### 2. Run pytest-atlas

```
<leader>tt
```

### 3. View the log

```
<leader>tL
```

### 4. Search for errors

In the log buffer:

```vim
/ERROR      " Jump to errors
/EXCEPTION  " Jump to exceptions
/WARN       " Jump to warnings
```

### 5. Trace execution flow

Look for the function entry/exit logs to see where execution stopped:

```
→ ENTER picker.show
→ ENTER runner.run
← EXIT runner.run      " ✓ Function completed
← EXIT picker.show     " ✓ Function completed
```

If a function enters but never exits, that's where it failed.

## Common Issues and Log Patterns

### Issue: Neovim exits when opening picker

**Look for:**
```
[DEBUG] Opening terminal with command: ...
[ERROR] ✗ EXCEPTION in runner.run: ...
```

**Likely cause:** Terminal callback issue (fixed in recent update)

### Issue: Picker doesn't show

**Look for:**
```
[WARN] Snacks picker not available: ...
[ERROR] No environments found in configuration
```

**Likely cause:** Snacks not initialized or missing environments.json

### Issue: No virtual environment found

**Look for:**
```
[DEBUG] Searching for virtual environments
[DEBUG] Found 0 virtual environments: {}
[WARN] No virtual environment found, using system Python
```

**Solution:** Create a virtual environment in the project root:
```bash
python -m venv .venv
```

### Issue: Tests don't run

**Look for:**
```
[INFO] Opening terminal with command: sh -c ...
[DEBUG] Terminal buffer created: 42
[DEBUG] Buffer options set for buf 42
```

Then check if the command looks correct. The full pytest command is logged.

## Adjusting Log Verbosity

### Set log level at runtime

```lua
-- In Neovim command mode
:lua require("pytest-atlas.logger").set_level("INFO")   -- Less verbose
:lua require("pytest-atlas.logger").set_level("DEBUG")  -- More verbose
:lua require("pytest-atlas.logger").set_level("ERROR")  -- Only errors
```

### Permanently change log level

Edit `lua/plugins/testing.lua`:

```lua
pytest_atlas.setup({
  debug = false,  -- Set to false for INFO level, true for DEBUG level
})
```

## Log File Management

### Automatic cleanup

The log file is cleared each time Neovim starts and pytest-atlas is loaded.

### Manual cleanup

```
<leader>tX
```

Or:

```vim
:PytestAtlasClearLog
```

### Viewing in external tool

```bash
# Follow log in real-time
tail -f ~/.cache/nvim/pytest-atlas.log

# Search for errors
grep ERROR ~/.cache/nvim/pytest-atlas.log

# View last 100 lines
tail -100 ~/.cache/nvim/pytest-atlas.log
```

## Tips

1. **Always clear logs before debugging** - Use `<leader>tX` to start fresh
2. **Use two terminals** - One running `tail -f` on the log, one with Neovim
3. **Check timestamps** - They help identify slow operations
4. **Look for gaps** - Missing function exits indicate crashes
5. **Search for EXCEPTION** - The stack trace shows exactly where it failed

## Getting Help

When reporting issues, please include:

1. Full log file contents (use `:PytestAtlasLog` and copy the buffer)
2. Neovim version (`:version`)
3. Steps to reproduce
4. Expected vs actual behavior

## See Also

- [Main README](README.md) - Plugin overview and features
- [Testing Keymaps](../../docs/KEYMAPS.md) - All testing-related keybindings
- [Troubleshooting](../../docs/TROUBLESHOOTING.md) - General troubleshooting guide
