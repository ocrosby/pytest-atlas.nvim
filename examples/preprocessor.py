#!/usr/bin/env python3
"""
Example preprocessor script for pytest-atlas.nvim

This script demonstrates how to create a custom preprocessor that runs
before pytest execution. It can be used to set up environment-specific
configuration, modify test parameters, or perform other preprocessing tasks.

Usage:
    python preprocessor.py process -e <environment> -r <region> [-m <markers>]

Example:
    python preprocessor.py process -e qa -r auto -m bdd
"""

import os
import sys
import subprocess
import click


@click.group()
def cli():
    """Pytest preprocessor for environment-specific test execution."""
    pass


@cli.command()
@click.option("-e", "--environment", required=True, help="Target environment (qa, fastly, prod)")
@click.option("-r", "--region", required=True, help="Target region (auto, use1, usw2, etc.)")
@click.option("-m", "--markers", default="bdd", help="Pytest markers to run")
def process(environment, region, markers):
    """
    Process and run pytest with environment-specific configuration.
    
    This is where you would add your custom preprocessing logic:
    - Load environment-specific configuration files
    - Set up environment variables
    - Modify test parameters
    - Run setup scripts
    """
    # Set environment variables
    os.environ["TEST_ENVIRONMENT"] = environment
    os.environ["TEST_REGION"] = region
    os.environ["TEST_MARKERS"] = markers
    
    click.echo(f"🔧 Preprocessing tests for {environment} ({region})")
    click.echo(f"📋 Markers: {markers}")
    
    # Example: Load environment-specific config
    config_file = f"config/{environment}.yaml"
    if os.path.exists(config_file):
        click.echo(f"✅ Loaded config: {config_file}")
    else:
        click.echo(f"⚠️  Config not found: {config_file} (using defaults)")
    
    # Build pytest command
    pytest_args = [
        "pytest",
        "--tb=short",
        "-v",
        f"-m={markers}",
    ]
    
    # Add allure if requested
    if os.environ.get("TEST_OPEN_ALLURE") == "true":
        pytest_args.append("--alluredir=allure-results")
    
    # Run pytest
    click.echo(f"🚀 Running: {' '.join(pytest_args)}")
    result = subprocess.run(pytest_args)
    
    # Exit with pytest's exit code
    sys.exit(result.returncode)


if __name__ == "__main__":
    cli()
