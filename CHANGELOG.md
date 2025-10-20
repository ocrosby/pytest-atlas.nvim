# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of pytest-atlas.nvim
- Interactive test picker for environment, region, and marker selection
- Automatic Python virtual environment detection
- Allure report integration
- Smart caching of test configurations
- Support for custom preprocessor scripts
- Comprehensive documentation and examples
- Test suite with plenary.nvim
- GitHub Actions CI/CD pipeline

## [1.0.0] - 2024-10-20

### Added
- Core plugin functionality extracted from yoda.nvim
- Main plugin module with setup function
- Configuration loader for environments.json and pytest.ini
- Virtual environment detection utilities
- Terminal configuration utilities
- Test picker with multi-step selection
- Test runner with environment variable support
- Plugin commands: PytestAtlasRun, PytestAtlasStatus
- Comprehensive README with usage examples
- Help documentation (doc/pytest-atlas.txt)
- Example configurations (examples/)
- Contributing guidelines
- MIT License
- Stylua configuration
- Makefile for testing
- GitHub Actions workflow for lint and test

[Unreleased]: https://github.com/ocrosby/pytest-atlas.nvim/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/ocrosby/pytest-atlas.nvim/releases/tag/v1.0.0
