function Test-FFmpegInstalled {
    $ffmpegPath = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Path
    if ($ffmpegPath) {
        Write-Host "FFmpeg found: $ffmpegPath" -ForegroundColor Green
        Write-Host "FFmpeg version: $(ffmpeg -version | Select-Object -First 1)"
        return $true
    }
    return $false
}

function Test-WingetAvailable {
    $wingetPath = (Get-Command winget -ErrorAction SilentlyContinue).Path
    if ($wingetPath) {
        return $true
    }
    return $false
}

function Refresh-PathEnvironment {
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$userPath;$machinePath"
}

function Install-FFmpegWithWinget {
    Write-Host "Installing FFmpeg using winget..." -ForegroundColor Cyan

    try {
        winget install Gyan.FFmpeg --accept-source-agreements --accept-package-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Host "FFmpeg installed successfully via winget." -ForegroundColor Green
            Refresh-PathEnvironment

            if (Test-FFmpegInstalled) {
                return $true
            } else {
                Write-Warning "FFmpeg was installed but is not yet in PATH. You may need to restart your terminal."
                return $true
            }
        } else {
            Write-Error "winget install failed with exit code: $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error "Error during winget installation: $($_.Exception.Message)"
        return $false
    }
}

function Show-ManualFFmpegInstallInstructions {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host "MANUAL FFMPEG INSTALLATION REQUIRED" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "winget is not available on this system."
    Write-Host "Please install FFmpeg manually:"
    Write-Host ""
    Write-Host "  1. Go to: https://www.gyan.dev/ffmpeg/builds/" -ForegroundColor Cyan
    Write-Host "  2. Download the 'ffmpeg-release-essentials' ZIP"
    Write-Host "  3. Extract to a folder (e.g., C:\ffmpeg)"
    Write-Host "  4. Add the 'bin' folder to your PATH"
    Write-Host "  5. Restart this installer after FFmpeg is installed"
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
}

function Install-FFmpeg {
    Write-Host "Checking for FFmpeg installation..." -ForegroundColor Cyan

    if (Test-FFmpegInstalled) {
        Write-Host "FFmpeg is already installed." -ForegroundColor Green
        return $true
    }

    Write-Host "FFmpeg not found. Attempting to install..." -ForegroundColor Yellow

    if (Test-WingetAvailable) {
        Write-Host "winget is available." -ForegroundColor Green
        return Install-FFmpegWithWinget
    } else {
        Write-Warning "winget is not available on this system."
        Show-ManualFFmpegInstallInstructions
        return $false
    }
}


## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

$ffmpegInstalled = Install-FFmpeg

if ($ffmpegInstalled) {
    Write-Host ""
    Write-Host "FFmpeg installation complete!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "FFmpeg installation was not completed. Please install manually and re-run the installer." -ForegroundColor Red
}
