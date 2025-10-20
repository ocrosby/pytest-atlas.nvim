# Contributing to pytest-atlas.nvim

Thank you for considering contributing to pytest-atlas.nvim! This document provides guidelines for contributing to the project.

## Code of Conduct

Be respectful and constructive in all interactions.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- A clear description of the problem
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Your Neovim version and OS
- Plugin configuration

### Suggesting Features

Feature requests are welcome! Please open an issue describing:
- The problem you're trying to solve
- Your proposed solution
- Any alternatives you've considered

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Format code with stylua (`stylua .`)
5. Add tests for new functionality
6. Run tests (`make test`)
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## Development Setup

### Prerequisites

- Neovim >= 0.9.0
- stylua (for code formatting)
- make

### Setup

1. Clone the repository:
```bash
git clone https://github.com/ocrosby/pytest-atlas.nvim.git
cd pytest-atlas.nvim
```

2. Install stylua:
```bash
# On macOS with Homebrew
brew install stylua

# On Linux
cargo install stylua
```

3. Run tests:
```bash
make test
```

## Code Style

- Follow the existing code style
- Use stylua for Lua formatting (`.stylua.toml` config provided)
- Add comments for complex logic
- Use clear, descriptive variable names
- Add type annotations where helpful

## Testing

- Add tests for new features in `tests/pytest-atlas/`
- Follow the existing test structure
- Tests use plenary.nvim's busted framework
- Run tests with `make test`

Example test:
```lua
describe("new feature", function()
  it("works as expected", function()
    local result = my_function()
    assert.are.equal("expected", result)
  end)
end)
```

## Documentation

- Update README.md for user-facing changes
- Update doc/pytest-atlas.txt for new commands/functions
- Add examples in the examples/ directory
- Include docstrings for public functions

Docstring format:
```lua
--- Brief description of function
--- @param param1 type Description of param1
--- @param param2 type Description of param2
--- @return type Description of return value
function M.my_function(param1, param2)
  -- Implementation
end
```

## Commit Messages

Follow conventional commit format:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Test changes
- `chore:` Build process or tooling changes

Example:
```
feat: add support for custom pytest arguments

- Allow users to pass additional pytest arguments
- Update documentation with examples
- Add tests for new functionality
```

## Release Process

Maintainers will handle releases:

1. Update version in README.md
2. Update CHANGELOG.md
3. Create a git tag
4. Push to GitHub
5. Create a GitHub release

## Questions?

Feel free to open an issue for questions or discussion!
