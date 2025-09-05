# update.ps1
# This script activates the 'default' virtual environment and updates the core packages.

function Update-MarimoPackages {
    # Define the path to the requirements file, assuming it's in the same directory as this script.
    $requirementsFile = Join-Path $PSScriptRoot "requirements.txt"

    try {
        Write-Host "Attempting to activate the 'default' virtual environment..."

        # The 'activate' command should be in the PATH.
        # We dot-source it to run it in the current scope so the environment changes apply.
        . activate "default"

        # Check if 'uv' command is available after activation.
        if (Get-Command uv -ErrorAction SilentlyContinue) {
            Write-Host "Environment activated. Updating packages from '$requirementsFile'..." -ForegroundColor Cyan
            
            # Use uv to upgrade the packages to their latest versions based on the requirements file.
            uv pip install --upgrade -r $requirementsFile

            if ($LASTEXITCODE -eq 0) {
                Write-Host "All packages updated successfully." -ForegroundColor Green
            } else {
                Write-Error "The package update process finished with an error. Exit code: $LASTEXITCODE"
            }
        } else {
            Write-Error "'uv' command not found after attempting to activate the environment."
            Write-Host "Please ensure the 'default' virtual environment exists and is correctly configured." -ForegroundColor Yellow
        }
    } catch {
        Write-Error "An error occurred while trying to activate the environment or update packages."
        Write-Error $_.Exception.Message
    }
}

# === Script Execution ===
# This allows the function to be imported without running the code below.
if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    Update-MarimoPackages
    Write-Host ""
    Read-Host "Update process finished. Press Enter to exit."
}