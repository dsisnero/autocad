# Install AutoCAD dependencies
# This script runs on Windows CI environment to prepare for UI tests

# Install Chocolatey packages if needed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
  Write-Output "Chocolatey not found. Using GitHub Actions pre-installed version."
}

# AutoCAD installation would normally go here
# In practice, you would need to:
# 1. Download AutoCAD installer from a secure location
# 2. Use license key from GitHub secrets
# 3. Install with silent options

Write-Output "Setting up AutoCAD environment for tests"

# Create mock registry entries if needed for tests
New-Item -Path "HKCU:\Software\Autodesk\AutoCAD" -Force | Out-Null

# Set environment variables needed by tests
[Environment]::SetEnvironmentVariable("AUTOCAD_TEST_MODE", "CI", "Process")

Write-Output "AutoCAD test environment setup complete"
