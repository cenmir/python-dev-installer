# m.ps1
# This script activates the 'default' virtual environment and then launches Marimo.

try {
    Write-Host "Activating 'default' virtual environment..."

    # The 'activate' command is expected to be in the PATH after installation.
    # We dot-source it to run it in the current scope so the environment changes apply here.
    . activate "default"

    # Check if the marimo command is now available after activation.
    if (Get-Command marimo -ErrorAction SilentlyContinue) {
        Write-Host "Launching Marimo..." -ForegroundColor Green
        Write-Host "Press Ctrl+C in this window to stop Marimo." -ForegroundColor Yellow
        
        # Launch marimo to edit files in the current directory.
        marimo edit
    } else {
        Write-Host "Error: 'marimo' command not found after attempting to activate the environment." -ForegroundColor Red
        Write-Host "Please ensure the 'default' virtual environment exists and Marimo is installed." -ForegroundColor Yellow
        Read-Host "Press Enter to exit..."
    }
} catch {
    Write-Host "An error occurred:" -ForegroundColor Red
    Write-Host "$($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
}