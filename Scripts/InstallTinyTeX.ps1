function Test-LaTeXInstalled {
    $pdflatex = (Get-Command pdflatex -ErrorAction SilentlyContinue).Path
    if ($pdflatex) {
        Write-Host "LaTeX found: $pdflatex" -ForegroundColor Green
        Write-Host "pdflatex version: $(pdflatex --version | Select-Object -First 1)"
        return $true
    }
    $xelatex = (Get-Command xelatex -ErrorAction SilentlyContinue).Path
    if ($xelatex) {
        Write-Host "LaTeX found: $xelatex" -ForegroundColor Green
        return $true
    }
    return $false
}

function Refresh-PathEnvironment {
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$userPath;$machinePath"
}

function Install-TinyTeXFromWeb {
    Write-Host "Downloading and installing TinyTeX..." -ForegroundColor Cyan
    Write-Host "This may take a few minutes." -ForegroundColor Yellow

    try {
        $installerUrl = "https://yihui.org/tinytex/install-bin-windows.ps1"
        $tempScript = Join-Path $env:TEMP "install-tinytex.ps1"

        Write-Host "Downloading installer from $installerUrl ..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $installerUrl -OutFile $tempScript -UseBasicParsing

        Write-Host "Running TinyTeX installer..." -ForegroundColor Cyan
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tempScript

        # Clean up temp file
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue

        Refresh-PathEnvironment

        if (Test-LaTeXInstalled) {
            return $true
        } else {
            Write-Warning "TinyTeX was installed but pdflatex is not yet in PATH. You may need to restart your terminal."
            return $true
        }
    }
    catch {
        Write-Error "Error during TinyTeX installation: $($_.Exception.Message)"
        return $false
    }
}

function Show-ManualTinyTeXInstallInstructions {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host "MANUAL TINYTEX INSTALLATION REQUIRED" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install TinyTeX manually:"
    Write-Host ""
    Write-Host "  1. Go to: https://yihui.org/tinytex/" -ForegroundColor Cyan
    Write-Host "  2. Follow the Windows installation instructions"
    Write-Host "  3. Restart this installer after TinyTeX is installed"
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
}

function Install-TinyTeX {
    Write-Host "Checking for LaTeX installation..." -ForegroundColor Cyan

    if (Test-LaTeXInstalled) {
        Write-Host "A LaTeX distribution is already installed." -ForegroundColor Green
        return $true
    }

    Write-Host "No LaTeX distribution found. Attempting to install TinyTeX..." -ForegroundColor Yellow

    $result = Install-TinyTeXFromWeb
    if ($result) {
        return $true
    } else {
        Show-ManualTinyTeXInstallInstructions
        return $false
    }
}


## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

$tinyTexInstalled = Install-TinyTeX

if ($tinyTexInstalled) {
    Write-Host ""
    Write-Host "TinyTeX installation complete!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "TinyTeX installation was not completed. Please install manually and re-run the installer." -ForegroundColor Red
}
