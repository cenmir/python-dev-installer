function Test-QuartoInstalled {
    $quartoPath = (Get-Command quarto -ErrorAction SilentlyContinue).Path
    if ($quartoPath) {
        Write-Host "Quarto found: $quartoPath" -ForegroundColor Green
        Write-Host "Quarto version: $(quarto --version)"
        return $true
    }
    return $false
}

function Refresh-PathEnvironment {
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$userPath;$machinePath"
}

function Get-QuartoDownloadUrl {
    # Query GitHub API for the latest quarto-cli release and pick the
    # 64-bit Windows portable zip (not the .msi).
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest" -UseBasicParsing

    $asset = $release.assets | Where-Object {
        $_.name -like "quarto-*-win.zip"
    } | Select-Object -First 1

    if (-not $asset) {
        throw "Could not find a Quarto Windows zip asset in the latest quarto-cli release."
    }

    return $asset.browser_download_url
}

function Download-AndExtractQuarto {
    param([string]$DownloadUrl)

    $zipPath = Join-Path $env:TEMP "quarto-download.zip"
    $installDir = "$env:LOCALAPPDATA\Quarto"

    $request = [System.Net.HttpWebRequest]::Create($DownloadUrl)
    $request.AllowAutoRedirect = $true
    $response = $request.GetResponse()
    $totalBytes = $response.ContentLength
    $stream = $response.GetResponseStream()
    $fileStream = [System.IO.File]::Create($zipPath)
    $buffer = New-Object byte[] 262144
    $totalRead = 0
    $lastPct = -1

    while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $fileStream.Write($buffer, 0, $bytesRead)
        $totalRead += $bytesRead
        if ($totalBytes -gt 0) {
            $pct = [int](($totalRead / $totalBytes) * 100)
            if ($pct -ne $lastPct) {
                $mbRead = [math]::Round($totalRead / 1MB, 1)
                $mbTotal = [math]::Round($totalBytes / 1MB, 1)
                Write-Progress -Activity "Downloading Quarto" -Status "${mbRead} MB / ${mbTotal} MB" -PercentComplete $pct
                $lastPct = $pct
            }
        }
    }

    $fileStream.Close()
    $stream.Close()
    $response.Close()
    Write-Progress -Activity "Downloading Quarto" -Completed

    Write-Host "Extracting to $installDir ..." -ForegroundColor Cyan
    if (Test-Path $installDir) {
        Remove-Item $installDir -Recurse -Force
    }

    # Extract to a temp folder first — the zip contains a versioned root
    # folder (quarto-X.Y.Z/) that we strip before moving to $installDir.
    $extractTemp = Join-Path $env:TEMP "quarto-extract"
    if (Test-Path $extractTemp) {
        Remove-Item $extractTemp -Recurse -Force
    }

    $tarExe = Get-Command tar.exe -ErrorAction SilentlyContinue
    if ($tarExe) {
        New-Item -Path $extractTemp -ItemType Directory | Out-Null
        & tar.exe -xf $zipPath -C $extractTemp
    } else {
        Expand-Archive -Path $zipPath -DestinationPath $extractTemp -Force
    }

    $innerFolder = Get-ChildItem -Path $extractTemp -Directory | Select-Object -First 1
    if ($innerFolder) {
        Move-Item -Path $innerFolder.FullName -Destination $installDir -Force
    } else {
        Move-Item -Path $extractTemp -Destination $installDir -Force
    }

    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue

    $binDir = Join-Path $installDir "bin"
    if (-not (Test-Path (Join-Path $binDir "quarto.exe"))) {
        throw "Extraction finished but quarto.exe was not found under $binDir."
    }

    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$binDir*") {
        [System.Environment]::SetEnvironmentVariable("PATH", "$userPath;$binDir", "User")
        Write-Host "Added $binDir to user PATH." -ForegroundColor Green
    }

    Refresh-PathEnvironment
}

function Show-ManualQuartoInstallInstructions {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host "MANUAL QUARTO INSTALLATION REQUIRED" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Automatic download of Quarto failed."
    Write-Host "Please install Quarto manually:"
    Write-Host ""
    Write-Host "  1. Go to: https://github.com/quarto-dev/quarto-cli/releases/latest" -ForegroundColor Cyan
    Write-Host "  2. Download the 'quarto-*-win.zip' asset"
    Write-Host "  3. Extract to a folder and add the 'bin' subfolder to PATH"
    Write-Host "  4. Restart this installer after Quarto is installed"
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
}

function Install-Quarto {
    Write-Host "Checking for Quarto installation..." -ForegroundColor Cyan

    if (Test-QuartoInstalled) {
        Write-Host "Quarto is already installed." -ForegroundColor Green
        return $true
    }

    Write-Host "Quarto not found. Installing portable Quarto to user profile..." -ForegroundColor Yellow
    Write-Host "No admin privileges required." -ForegroundColor Green

    try {
        $url = Get-QuartoDownloadUrl
        Write-Host "Downloading Quarto from $url" -ForegroundColor Cyan
        Download-AndExtractQuarto -DownloadUrl $url

        if (Test-QuartoInstalled) { return $true }
        Write-Warning "Quarto was installed but is not yet in PATH. You may need to restart your terminal."
        return $true
    }
    catch {
        Write-Warning "Quarto install failed: $($_.Exception.Message)"
        Show-ManualQuartoInstallInstructions
        return $false
    }
}


## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

$quartoInstalled = Install-Quarto

if ($quartoInstalled) {
    Write-Host ""
    Write-Host "Quarto installation complete!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Quarto installation was not completed. Please install manually and re-run the installer." -ForegroundColor Red
}
