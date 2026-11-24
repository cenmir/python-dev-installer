function Install-Requirements {
    # Installs requirements.txt into the active venv and reports uv's result.
    # A git+https line needs git on PATH; without git we install the same
    # repository's main branch as a GitHub zip archive instead, so one missing
    # tool does not stop every other package from installing.
    param(
        [Parameter(Mandatory)][string]$RequirementsFile,
        [switch]$Upgrade
    )

    $reqs = $RequirementsFile
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $lines = Get-Content $RequirementsFile
        if ($lines -match 'git\+https://github\.com/') {
            Write-Host "Git not found; installing GitHub packages from zip archives instead." -ForegroundColor Yellow
            $reqs = Join-Path $env:TEMP "requirements-nogit.txt"
            $lines -replace 'git\+(https://github\.com/[^/\s]+/[^/\s]+?)(\.git)?$', '$1/archive/refs/heads/main.zip' |
                Set-Content $reqs -Encoding ASCII
        }
    }

    if ($Upgrade) {
        uv pip install --upgrade -r $reqs
    } else {
        uv pip install -r $reqs
    }
    $code = $LASTEXITCODE
    if ($code -eq 0) {
        Write-Host "Packages installed successfully." -ForegroundColor Green
        return $true
    }
    Write-Host "Package installation failed (uv exit code $code). See the messages above." -ForegroundColor Red
    return $false
}

function InstallPackages{
    # Define the path for the virtual environment
    $venvPath = Join-Path $env:USERPROFILE ".venvs\default"

    # Define the packages to install
    #$packages = "numpy", "sympy", "scipy", "matplotlib", "marimo", "imageio"
    # Define the path to the requirements file
    $requirementsFile = Join-Path $PSScriptRoot "requirements.txt"

    try {

        # Check if the virtual environment was created successfully
        if (Test-Path $venvPath) {

            # Define the path to the activate script for Windows
            $activateScript = Join-Path $venvPath "Scripts\Activate.ps1"

            # Check if the activate script exists
            if (Test-Path $activateScript) {
                Write-Host "Activating the virtual environment..."

                # Run the activate script to set environment variables (PATH, VIRTUAL_ENV)
                # Note: '&' runs in child scope, but $env: variables persist process-wide
                & $activateScript

                # Now that the venv is activated, uv should be in the PATH
                Write-Host "Installing packages from '$requirementsFile'..."
                return (Install-Requirements -RequirementsFile $requirementsFile)

                # Optional: Deactivate the environment if you want to return to the global environment
                # Write-Host "Deactivating the virtual environment..."
                # Deactivate-Venv # This function is typically available after activation in the same session
            }
            else {
                Write-Host "Error: Activate script not found at '$activateScript'." -ForegroundColor Red
                return $false
            }
        }
        else {
            Write-Host "Error: Failed to create virtual environment at '$venvPath'." -ForegroundColor Red
            return $false
        }

    } catch {
        # Catch any errors that occur during the script execution.
        Write-Host "An error occurred during setup: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function CreateDefaultVenv{

    $VenvPath = Join-Path $env:USERPROFILE ".venvs\default"

    # Check if venv already exists
    if (Test-Path $VenvPath) {
        Write-Host ""
        Write-Host "Virtual environment already exists at: $VenvPath" -ForegroundColor Yellow
        Write-Host "Recreating it will DELETE all installed packages and reset to defaults."
        Write-Host ""
        $response = Read-Host "Do you want to recreate the virtual environment? (y/N)"
        if ($response -notmatch '^[Yy]') {
            Write-Host "Keeping existing virtual environment." -ForegroundColor Green
            return $true  # Return true so packages still get installed/updated
        }
        Write-Host "Recreating virtual environment..." -ForegroundColor Yellow
    } else {
        Write-Host "Creating virtual environment at: $VenvPath" -ForegroundColor Cyan
    }

    try {
        # Create the venv. uv will create parent directories if they don't exist.
        uv venv --clear --python 3.13 $VenvPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Virtual environment created successfully at: $VenvPath" -ForegroundColor Green
            return $true
        } else {
            Write-Error "Failed to create virtual environment at $VenvPath. uv exit code: $LASTEXITCODE"
            return $false
        }
    } catch {
        Write-Error "An error occurred during venv creation: $_"
        return $false
    }

}

## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

CreateDefaultVenv


InstallPackages


Write-Host ""
Write-Host "Creation of default virtual environment and package installation process has completed."
#Read-Host "Press Enter to exit this setup script..."