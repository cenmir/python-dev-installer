# Marimo JTH installer

This repository contains installation files for installing the Marimo editor used in courses at JTH (School of Engineering, Jönköping University). These installation files will help you set up the Marimo editor on either the JTH computer lab machines or your personal computer running windows.

For Mac or Linux users, please refer to the [Marimo installation guide for Mac/Linux](https://mechanics.ju.se/python_installation.html).

## What the installer does

The installer will:
- Install the package manager uv
- Install the latest version of Python
- Create a virtual environment at `C:\Users\username\venvs\default`
- Install packages, including Marimo, into the virtual environment along with numpy, sympy, matplotlib, pandas, pyqt6, pyqtgraph and scipy. This is configurable using the `requirements.txt` file.
- Copy the run scripts to a folder in `C:\Users\username\marimo` and put that folder in your user PATH environment variable
- Create shortcuts to launch Marimo
- Create a context menu entry to open folders in Marimo (very useful for opening projects!)

## Installation Instructions

1. Download the repo as a ZIP file and extract it to a folder on your computer.
2. Open the extracted folder and run the `setup.bat` file by double-clicking it.
3. Follow the on-screen instructions to complete the installation process.

## Usage

- You can launch Marimo by right-clicking in a folder and selecting "Open in Marimo" or by using the shortcut created on your desktop.
- You can also run Marimo from the command line by typing `m`.
- You can update Marimo and the installed packages by right-clicking on the `update.ps1` file and selecting "Run with PowerShell".
- If you want to uninstall Marimo, you can run the `uninstall.ps1` file and selecting "Run with PowerShell".


### Easy .venv setup for new projects for vs-code users

There is a useful file in Scripts called `init.bat` which you can copy to a new project folder and double-clicking it will create a virtual environment (.venv) for that project and install the above mentioned packages. Useful if you want to keep dependencies separate between projects. VS-Code will automatically detect the .venv folder and use it as the Python interpreter for that project.
