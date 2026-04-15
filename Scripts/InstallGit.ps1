function Test-GitInstalled {
    $gitPath = (Get-Command git -ErrorAction SilentlyContinue).Path
    if ($gitPath) {
        Write-Host "Git found: $gitPath" -ForegroundColor Green
        Write-Host "Git version: $(git --version)"
        return $true
    }
    return $false
}

function Refresh-PathEnvironment {
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$userPath;$machinePath"
}

function Get-MinGitDownloadUrl {
    # Query GitHub API for the latest Git for Windows release and pick the
    # 64-bit MinGit asset (not the busybox variant).
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest" -UseBasicParsing

    $asset = $release.assets | Where-Object {
        $_.name -like "MinGit-*-64-bit.zip" -and $_.name -notlike "*busybox*"
    } | Select-Object -First 1

    if (-not $asset) {
        throw "Could not find a MinGit 64-bit zip asset in the latest Git for Windows release."
    }

    return $asset.browser_download_url
}

function Download-AndExtractMinGit {
    param([string]$DownloadUrl)

    $zipPath = Join-Path $env:TEMP "mingit-download.zip"
    $installDir = "$env:LOCALAPPDATA\MinGit"

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
                Write-Progress -Activity "Downloading MinGit" -Status "${mbRead} MB / ${mbTotal} MB" -PercentComplete $pct
                $lastPct = $pct
            }
        }
    }

    $fileStream.Close()
    $stream.Close()
    $response.Close()
    Write-Progress -Activity "Downloading MinGit" -Completed

    Write-Host "Extracting to $installDir ..." -ForegroundColor Cyan
    if (Test-Path $installDir) {
        Remove-Item $installDir -Recurse -Force
    }

    $tarExe = Get-Command tar.exe -ErrorAction SilentlyContinue
    if ($tarExe) {
        New-Item -Path $installDir -ItemType Directory | Out-Null
        & tar.exe -xf $zipPath -C $installDir
    } else {
        Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
    }

    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

    $cmdDir = Join-Path $installDir "cmd"
    if (-not (Test-Path (Join-Path $cmdDir "git.exe"))) {
        throw "Extraction finished but git.exe was not found under $cmdDir."
    }

    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$cmdDir*") {
        [System.Environment]::SetEnvironmentVariable("PATH", "$userPath;$cmdDir", "User")
        Write-Host "Added $cmdDir to user PATH." -ForegroundColor Green
    }

    Refresh-PathEnvironment
}

function Show-ManualInstallInstructions {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host "MANUAL GIT INSTALLATION REQUIRED" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Automatic download of MinGit failed."
    Write-Host "Please install Git manually:"
    Write-Host ""
    Write-Host "  1. Go to: https://git-scm.com/download/win" -ForegroundColor Cyan
    Write-Host "  2. Download and extract the 'MinGit' 64-bit zip"
    Write-Host "     from the Git for Windows release page:"
    Write-Host "     https://github.com/git-for-windows/git/releases/latest" -ForegroundColor Cyan
    Write-Host "  3. Extract to a folder and add the 'cmd' subfolder to PATH"
    Write-Host "  4. Restart this installer after Git is installed"
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
}

function Install-Git {
    Write-Host "Checking for Git installation..." -ForegroundColor Cyan

    if (Test-GitInstalled) {
        Write-Host "Git is already installed." -ForegroundColor Green
        return $true
    }

    Write-Host "Git not found. Installing MinGit (portable) to user profile..." -ForegroundColor Yellow
    Write-Host "No admin privileges required." -ForegroundColor Green

    try {
        $url = Get-MinGitDownloadUrl
        Write-Host "Downloading MinGit from $url" -ForegroundColor Cyan
        Download-AndExtractMinGit -DownloadUrl $url

        if (Test-GitInstalled) { return $true }
        Write-Warning "MinGit was installed but is not yet in PATH. You may need to restart your terminal."
        return $true
    }
    catch {
        Write-Warning "MinGit install failed: $($_.Exception.Message)"
        Show-ManualInstallInstructions
        return $false
    }
}

function Test-GitConfigured {
    $userName = git config --global user.name 2>$null
    $userEmail = git config --global user.email 2>$null

    if ($userName -and $userEmail) {
        return $true
    }
    return $false
}

function Set-GitConfig {
    Write-Host ""
    Write-Host "Git Configuration" -ForegroundColor Cyan
    Write-Host "-----------------" -ForegroundColor Cyan

    $existingName = git config --global user.name 2>$null
    $existingEmail = git config --global user.email 2>$null

    if ($existingName -and $existingEmail) {
        Write-Host "Git is already configured:" -ForegroundColor Green
        Write-Host "  Name:  $existingName"
        Write-Host "  Email: $existingEmail"

        $reconfigure = Read-Host "Do you want to change these settings? (y/N)"
        if ($reconfigure -notmatch '^[Yy]') {
            Write-Host "Keeping existing configuration." -ForegroundColor Green
            return $true
        }
    }

    Write-Host ""
    Write-Host "Please enter your details for Git commits:" -ForegroundColor Yellow
    Write-Host "(This identifies you as the author of your code)"
    Write-Host ""

    $userName = Read-Host "Your name (e.g., 'John Doe')"
    if ([string]::IsNullOrWhiteSpace($userName)) {
        Write-Warning "Name cannot be empty. Git configuration skipped."
        Write-Host "You can configure later with: git config --global user.name 'Your Name'"
        return $false
    }

    $userEmail = Read-Host "Your email (e.g., 'john.doe@example.com')"
    if ([string]::IsNullOrWhiteSpace($userEmail)) {
        Write-Warning "Email cannot be empty. Git configuration skipped."
        Write-Host "You can configure later with: git config --global user.email 'your@email.com'"
        return $false
    }

    try {
        git config --global user.name $userName
        git config --global user.email $userEmail

        Write-Host ""
        Write-Host "Git configured successfully!" -ForegroundColor Green
        Write-Host "  Name:  $userName"
        Write-Host "  Email: $userEmail"
        return $true
    }
    catch {
        Write-Error "Failed to configure Git: $($_.Exception.Message)"
        return $false
    }
}


## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

$gitInstalled = Install-Git

if ($gitInstalled) {
    Write-Host ""
    Write-Host "Git installation complete!" -ForegroundColor Green

    Set-GitConfig
} else {
    Write-Host ""
    Write-Host "Git installation was not completed. Please install manually and re-run the installer." -ForegroundColor Red
}
