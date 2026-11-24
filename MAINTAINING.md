# Maintaining the installer

Notes for whoever changes this repository next. README.md says what the installer does
for students; this file says how it is built, released, mirrored and tested, and which
traps have already bitten.

## Entry points

| How a student starts it | What runs |
|---|---|
| `irm https://raw.githubusercontent.com/cenmir/python-dev-installer/main/download.ps1 \| iex` | `download.ps1`: fetches the repo ZIP (GitHub first, then the mirror), runs `Scripts\Install.ps1` |
| `irm https://mechanics.ju.se/installer/install.ps1 \| iex` | the same `download.ps1` with the mirror tried first (see *Mirror*) |
| ZIP from GitHub or the mirror, then `setup.bat` | `Scripts\Install.ps1` |
| Start Menu: Update Marimo | `updateScripts.ps1` in `~\marimo`: downloads the latest **release** and copies `Scripts\` over |
| `repair.bat`, `uninstall.bat`, `update.bat` in `~\marimo` | `repair.ps1`, `uninstall.ps1`, `update.ps1` (packages only) |

The book pages that describe it: `Preliminaries/python_installation.qmd` (the one-liner,
the mirror, what the installer does) and `Mechatronics/PlatformIO.qmd` in the mechanics
book (Step 1, and section `#sec-pio-plug`, which shows the same PlatformIO toolbar
setting as `InstallPlatformIO.ps1`; keep the two identical).

## Rules every script follows

- **Windows PowerShell 5.1.** `setup.bat`, `download.ps1` and every shortcut start
  `powershell.exe`, not `pwsh`. No PowerShell 7 features: no `ConvertFrom-Json
  -AsHashtable`, no `??`, no ternary. Use `PSCustomObject` + `Add-Member -Force` to edit
  JSON (`Update-VSCodeUserSettings` in `InstallVSCode.ps1` does this).
- **No admin.** Everything installs per user: portable ZIPs in `%LOCALAPPDATA%`, user
  PATH, `HKCU` registry. VS Code is the one winget install (its user-scope installer).
- **Each `Install*.ps1` stands alone** and ends with a dot-source guard
  (`if ($MyInvocation.InvocationName -eq '.') { return }`), so other scripts can
  `. "$PSScriptRoot\InstallVSCode.ps1"` to reuse functions without installing anything.
  Small helpers (`Refresh-PathEnvironment`, `Get-LatestReleaseTag`) are repeated per
  file on purpose.
- **TLS:** add, never replace. Each downloader ORs in TLS 1.2, and TLS 1.3 on Windows 11
  (build 22000+), into `[Net.ServicePointManager]::SecurityProtocol`. Forcing TLS 1.2
  alone locks out mechanics.ju.se, which accepts TLS 1.3 only.
- **GitHub API rate limit:** 60 unauthenticated requests per hour per IP address, and a
  classroom shares one. Every API lookup has a fallback: `Get-LatestReleaseTag` reads the
  redirect of `github.com/<repo>/releases/latest` and builds the asset URL from the tag
  (Git, TinyTeX, Quarto); the update check and updater fall back to the mirror.
- **Keep `download.ps1` pure ASCII.** The mirror serves `.ps1` as
  `application/octet-stream`, which PowerShell 5.1 decodes in the legacy code page.
  `tools/build_installer.py` refuses non-ASCII.

## Where things are installed

| Component | Location | On PATH |
|---|---|---|
| Git (MinGit) | `%LOCALAPPDATA%\MinGit` | `...\MinGit\cmd` |
| Quarto | `%LOCALAPPDATA%\Quarto` | `...\Quarto\bin` |
| FFmpeg | `%LOCALAPPDATA%\FFmpeg` | `...\FFmpeg\bin` |
| TinyTeX | `%APPDATA%\TinyTeX` | `...\bin\windows` |
| uv | `%USERPROFILE%\.local\bin\uv.exe` (folder shared with other tools: Claude Code, pipx) | yes |
| Python 3.13 | `%APPDATA%\uv\python` | via uv |
| venv | `%USERPROFILE%\.venvs\default`, packages from `Scripts\requirements.txt` | `activate default` |
| Marimo scripts | `%USERPROFILE%\marimo` (copy of `Scripts\`) | yes |
| VS Code | winget, user scope | `...\Microsoft VS Code\bin` |

Archive layouts the extractors depend on (checked 2026-11-24):
Quarto `quarto-X-win.zip` has `bin\` and `share\` **at the root** (no versioned folder);
MinGit has `cmd\git.exe` at the root; the gyan.dev FFmpeg ZIP has one versioned folder.
If an extractor breaks, list the archive first.

## The menu in Install.ps1

`$menuItems`, `$mainDefaults` (which items start ticked; PlatformIO starts unticked),
`-ExpandableIndex` (the *Windows configuration* submenu, currently 10) and the
`$choices[n]` blocks below the menu all use the same positions. Adding an item means
updating all four.

## Shared pieces

- `contextMenus.ps1`: the Marimo right-click entries (`.py` files: Open with Marimo;
  folders and folder background: Open in Marimo). Used by Install, repair and uninstall.
  Versions before 2.4.0 registered the file entry under `HKCU:\Software\Classes\*`; that
  key is literally named `*`, so always address it with `-LiteralPath`.
- `InstallVSCode.ps1`: `Get-VSCodeCli` (finds `code.cmd` even when VS Code is not on
  PATH), `Install-VSCodeExtensions -Extensions`, `Update-VSCodeUserSettings`.
- `InstallPlatformIO.ps1`: `$PlatformIOExtensions`, `Set-PlatformIOToolbar`.
- `createDefaultVenvAndInstallPackages.ps1`: `Install-Requirements [-Upgrade]` (used by
  repair and update too). Without git it rewrites `git+https://github.com/o/r.git` lines
  to `https://github.com/o/r/archive/refs/heads/main.zip`.

## Releasing

The update check compares `Scripts\version.txt` with the latest **GitHub release** and
reports only a newer one; Update Marimo installs that release. So a version bump without
a release does nothing for installed copies.

1. Bump `Scripts\version.txt` and the date in the banner of `Install.ps1`.
2. Commit and `git push origin main`. `origin` pushes to GitHub
   (`git@github-cenmir:...`) and to the jthgit mirror (`git@jthgit:mirza/python-dev-installer.git`).
3. `gh release create vX.Y.Z --target main --title "..." --notes-file notes.md`, then
   `git fetch --tags && git push origin vX.Y.Z` so jthgit has the tag too.
4. Rebuild the mirror and publish the book (next section).

## Mirror on mechanics.ju.se

`https://mechanics.ju.se/installer/` holds `python-dev-installer.zip` (HEAD of this repo,
in one folder `python-dev-installer-main\` like GitHub's ZIP, without `.claude/`,
`.gitignore`, `todo.md`), `install.ps1` (`download.ps1` with the two sources swapped) and
`version.txt`.

It is built by the mechanics book, from **committed HEAD** of `~/python-dev-installer`:

```bash
cd ~/mechanics
env -u PYTHONPATH .venv/bin/python tools/build_installer.py   # writes installer/ and _book/installer/
```

`installer/` is committed in the book and listed under `resources` in `_quarto.yml`, so
every full publish deploys it (the full deploy is `rsync --delete` of `_book/`; files
put on the server any other way are deleted by it). `publish.py --only` copies chapter
pages only, not `installer/`; between full publishes,
`cp installer/* /var/www/mechanics/installer/` updates the live copy (the web root is
writable by mirza, no sudo needed). Do not run `publish.py` (which renders) while
`quarto preview` runs.

If the `$sources` block in `download.ps1` changes, update `GITHUB_SOURCE` and
`MIRROR_SOURCE` in `build_installer.py`, which swaps them by exact text.

mechanics.ju.se accepts TLS 1.3 only (`/etc/nginx/snippets/ssl-params.conf`, shared by
six sites). Windows 10 has no TLS 1.3 in PowerShell, so the mirror is Windows 11 only.
Decided 2026-11-24: Windows 10 is not supported, the server stays at TLS 1.3.

## Testing on dolores

There is no `pwsh` on the Linux box. `ssh dolores` reaches a Windows 11 machine with
Windows PowerShell 5.1, the same as a student's PC. Pattern:

```bash
cd ~/python-dev-installer
ssh dolores 'New-Item -ItemType Directory -Force $env:TEMP\pdi-test | Out-Null'
tar -C Scripts -cf - $(cd Scripts; ls *.ps1) | ssh dolores 'cd $env:TEMP\pdi-test; tar -xf -'
tar -cf - test.ps1 | ssh dolores 'cd $env:TEMP\pdi-test; tar -xf -'
ssh dolores 'powershell -NoProfile -ExecutionPolicy Bypass -File $env:TEMP\pdi-test\test.ps1; Remove-Item -Recurse -Force $env:TEMP\pdi-test'
```

- Run test scripts with `-File`; piping a script into `powershell -Command -` prints nothing.
- Start every test with a parse check of all scripts:
  `[System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$null, [ref]$errs)`.
- Dot-source an installer to call its functions without running it.
- Point install functions at temp folders (`Download-AndExtractQuarto -InstallDir ... -NoPath`)
  and registry code at `HKCU:\Software\pdi-test`, then delete them.
- Never run the full menu, the uninstaller or repair on dolores: they change the real
  user profile (dolores has its own Quarto, VS Code with 45 extensions, Claude Code in
  `~\.local\bin`).
- To test `download.ps1`, replace its final `powershell.exe ... -File $installScript`
  line with a `Write-Host` and pipe the text to `iex`.

## Traps already found

- `Write-Host "=" * 60` prints `= * 60`; write `Write-Host ("=" * 60)`.
- `settings.json` may contain comments or trailing commas; `ConvertFrom-Json` fails on
  them. The merge then leaves the file alone and prints the block to paste. Never
  replace the file.
- `uv pip install` must be followed by a `$LASTEXITCODE` check; it does not throw.
- `Write-Error` has no `-ForegroundColor`.
- `ConvertTo-Json` in 5.1 indents oddly; the output is valid JSON, and VS Code accepts it.
- The uninstaller must not delete `~\.local\bin` (shared), must ask before wiping VS
  Code, and must not ask winget to remove Git or Quarto (portable here; winget would
  remove the student's own copies).
