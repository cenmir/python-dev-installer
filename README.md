# Mechanical Engineering Python Development Setup

This repository contains installation files for setting up a Python development environment for Mechanical Engineering courses at JTH (School of Engineering, Jonkoping University). It installs Git, VS Code, Quarto, TinyTeX, FFmpeg, Python, and the Marimo notebook editor on Windows. An interactive menu lets you select which components to install.

For Mac or Linux users, please refer to the [Marimo installation guide for Mac/Linux](https://python.ju.se/python_installation.html#manual-python-installation).

## Quick Install

Open **PowerShell** and paste:

```powershell
irm https://raw.githubusercontent.com/cenmir/python-dev-installer/main/download.ps1 | iex
```

If GitHub cannot be reached, the same installer is mirrored on the mechanics book's site:

```powershell
irm https://mechanics.ju.se/installer/install.ps1 | iex
```

The mirror is rebuilt from this repository's HEAD by `tools/build_installer.py` in the mechanics book and deployed with the book.

> **Execution policy error?** If PowerShell blocks the script, run this first to allow scripts for the current user:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```

---

## Alternative: Manual download

1. Download the repo as a ZIP file and extract it
2. Run `setup.bat` by double-clicking it
3. Follow the on-screen instructions

## What the installer does

### Software Installation
- **Git** - Version control (prompts for name/email configuration)
- **VS Code** - Code editor with Python and Jupyter extensions, context menu integration
- **PlatformIO for ESP32** (unticked by default) - PlatformIO IDE, Microsoft Serial Monitor and Teleplot extensions; the PlatformIO toolbar plug button opens Microsoft's Serial Monitor
- **Quarto** - Scientific and technical publishing (portable, no admin)
- **TinyTeX** - LaTeX distribution for PDF rendering
- **FFmpeg** - Audio/video processing toolkit
- **uv + Python** - Fast package manager and Python 3.13

### Python Environment
- Creates virtual environment at `~\.venvs\default`
- Installs packages: numpy, sympy, scipy, matplotlib, marimo, imageio, pyqt6, pyqtgraph, pandas, ipykernel, nbformat, nbclient, MechanicsKit
- Packages are configurable via `Scripts/requirements.txt`

### Marimo Setup
- Copies scripts to `~\marimo` and adds it to user PATH
- Creates Start Menu shortcuts (Marimo, New Notebook, Update, Uninstall)
- Adds "Open with Marimo" to `.py` files and "Open in Marimo" to folders (right-click on and inside a folder)
- Configures dark mode by default (`~/.marimo.toml`)

### Windows Configuration (submenu)
- Install Windows Terminal (if not present)
- Pin user profile folder to Quick Access
- Show hidden files and folders
- Show file extensions
- Enable classic context menu (removes Windows 11 "Show more options")

## Usage

- **Launch Marimo**: Right-click in a folder > "Open in Marimo", or Start Menu, or type `m` in the terminal
- **Open in VS Code**: Right-click on any folder > "Open with VS Code"
- **Update**: Double-click `update.bat` in `~\marimo`, or use the Start Menu shortcut
- **Repair**: Double-click `repair.bat` in `~\marimo` to fix broken venvs, VS Code (reinstalls every extension that was installed), PATH, context menus, or shortcuts
- **Uninstall**: Double-click `uninstall.bat` in `~\marimo`, or use the Start Menu shortcut. It asks before removing anything, and asks separately before deleting VS Code settings and extensions

## Project-specific Virtual Environments

Copy `Scripts/init.bat` to your project folder and double-click it. This creates a local `.venv` that VS Code will automatically detect and use.

Maintainers: see [MAINTAINING.md](MAINTAINING.md) for releasing, the mirror, testing and known traps.

## Repository Files

### Root

| File | Purpose |
|------|---------|
| `download.ps1` | One-liner bootstrap: downloads repo ZIP, extracts, runs `Scripts/Install.ps1` |
| `setup.bat` | Manual install entry point: double-click after extracting the ZIP |
| `README.md` | This file |

### Scripts/ - Installers

| File | Purpose |
|------|---------|
| `Install.ps1` | Main orchestrator: interactive menu, calls all installers, configures system |
| `InstallGit.ps1` | Installs Git via winget, prompts for user.name/email |
| `InstallVSCode.ps1` | Installs VS Code via winget, adds extensions and context menus |
| `InstallPlatformIO.ps1` | Adds the PlatformIO, Serial Monitor and Teleplot extensions and the `platformio-ide.toolbar` setting |
| `InstallQuarto.ps1` | Downloads the portable Quarto zip from GitHub to `%LOCALAPPDATA%\Quarto` and adds it to PATH |
| `InstallTinyTeX.ps1` | Detects any LaTeX distro, installs TinyTeX if none found |
| `InstallFFmpeg.ps1` | Downloads and installs FFmpeg from gyan.dev (GitHub fallback) |
| `InstallPython.ps1` | Installs uv and Python 3.13 |
| `createDefaultVenvAndInstallPackages.ps1` | Creates `~\.venvs\default` and installs packages from `requirements.txt` |

### Scripts/ - Runtime

| File | Purpose |
|------|---------|
| `m.ps1` / `m.cmd` | Marimo launcher shortcut (type `m` in terminal) |
| `runMarimo.ps1` | Opens Marimo in a given folder |
| `runMarimoFile.ps1` | Opens a file in Marimo |
| `runMarimoTemp.ps1` | Creates and opens a new Marimo notebook |
| `contextMenus.ps1` | Registers and removes the Marimo right-click entries (used by Install, repair, uninstall) |
| `activate.ps1` | Adds/removes `~\marimo` to user PATH |

### Scripts/ - Maintenance

| File | Purpose |
|------|---------|
| `update.ps1` / `update.bat` | Updates Python packages in the default venv |
| `updateScripts.ps1` | Downloads latest scripts from GitHub |
| `checkUpdate.ps1` | Checks if a newer version is available |
| `repair.ps1` / `repair.bat` | Fixes broken venvs, VS Code, PATH entries, context menus, shortcuts |
| `uninstall.ps1` / `uninstall.bat` | Full uninstaller: removes all tools, data, registry keys, and PATH entries |

### Scripts/ - Configuration

| File | Purpose |
|------|---------|
| `requirements.txt` | Python packages to install (single source of truth) |
| `init.bat` | Project-specific venv creator (copy to project folder, double-click) |
| `version.txt` | Current version tag (used by update checker) |
| `config.json` | Installer configuration |
| `mo.ico` | Marimo icon for shortcuts and context menus |
