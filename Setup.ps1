# ██╗    ██╗██╗███╗   ██╗██████╗  ██████╗ ████████╗███████╗
# ██║    ██║██║████╗  ██║██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝
# ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██║   ██║   ██║   ███████╗
# ██║███╗██║██║██║╚██╗██║██║  ██║██║   ██║   ██║   ╚════██║
# ╚███╔███╔╝██║██║ ╚████║██████╔╝╚██████╔╝   ██║   ███████║
#  ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝    ╚═╝   ╚══════╝
# Setup.ps1 - Scott McKendry
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#Requires -RunAsAdministrator
#Requires -Version 7

# Linked Files (Destination => Source)
$symlinks = @{
    $PROFILE.CurrentUserAllHosts                                                                    = ".\Profile.ps1"
    "$HOME\AppData\Local\nvim"                                                                      = ".\nvim"
    "$HOME\AppData\Local\fastfetch"                                                                 = ".\fastfetch"
    "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" = ".\windowsterminal\settings.json"
    "$HOME\.gitconfig"                                                                              = ".\.gitconfig"
    "$HOME\AppData\Roaming\lazygit"                                                                 = ".\lazygit"
    "$HOME\AppData\Roaming\AltSnap\AltSnap.ini"                                                     = ".\altsnap\AltSnap.ini"
    "$ENV:PROGRAMFILES\WezTerm\wezterm_modules"                                                     = ".\wezterm\"
}

# Winget & choco dependencies
$wingetDeps = @(
    "chocolatey.chocolatey"
    "eza-community.eza" # eza is a modern, maintained replacement for the venerable file-listing command-line program ls that ships with Unix and Linux operating systems, giving it more features and better defaults.
    "ezwinports.make"
    "fastfetch-cli.fastfetch"
    "gerardog.gsudo"
    "git.git"
    "github.cli"
    "kitware.cmake"
    "mbuilov.sed"
    "microsoft.powershell"
    "neovim.neovim"
    "openjs.nodejs"
    "starship.starship"
    # "AltSnap.AltSnap"
    # "sharkdp.bat"
    # "sharkdp.fd"
    # "junegunn.fzf"
    # "BurntSushi.ripgrep.MSVC"
    # "JesseDuffield.lazygit"
    # "DEVCOM.JetBrainsMonoNerdFont"
    # "wez.wezterm"
    # "zig.zig"
    # "ajeetdsouza.zoxide"
)
$chocoDeps = @(
    "altsnap" # It allows you to move and resize windows by using the Alt key and clicking wherever on the window instead of relying on very precise clicking.
    "bat" # bat supports syntax highlighting for a large number of programming and markup languages
    "fd" # fd is a program to find entries in your filesystem
    "fzf" # fzf is a general-purpose command-line fuzzy finder
    "gawk" # The (g)awk utility interprets a special-purpose programming language that makes it possible to handle simple data-reformatting jobs with just a few lines of code.
    "lazygit"
    "mingw" # A native Windows port of the GNU Compiler Collection (GCC)
    "nerd-fonts-jetbrainsmono"
    "ripgrep" # ripgrep is a line-oriented search tool that recursively searches the current directory for a regex pattern.
    "sqlite"
    "wezterm" # WezTerm is a powerful cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust
    "zig" # Zig is a general-purpose programming language and toolchain for maintaining robust, optimal and reusable software.
    "zoxide" # zoxide is a smarter cd command, inspired by z and autojump.
)

# PS Modules
$psModules = @(
    "CompletionPredictor"
    "PSScriptAnalyzer"
    "ps-arch-wsl"
    "ps-color-scripts"
)

# Set working directory
Set-Location $PSScriptRoot
[Environment]::CurrentDirectory = $PSScriptRoot

Write-Host "Installing missing dependencies..."
$installedWingetDeps = winget list | Out-String
foreach ($wingetDep in $wingetDeps) {
    if ($installedWingetDeps -notmatch $wingetDep) {
        winget install --id $wingetDep
    }
}

# Path Refresh
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

$installedChocoDeps = (choco list --limit-output --id-only).Split("`n")
foreach ($chocoDep in $chocoDeps) {
    if ($installedChocoDeps -notcontains $chocoDep) {
        choco install $chocoDep -y
    }
}

# Install PS Modules
foreach ($psModule in $psModules) {
    if (!(Get-Module -ListAvailable -Name $psModule)) {
        Install-Module -Name $psModule -Force -AcceptLicense -Scope CurrentUser
    }
}

# Delete OOTB Nvim Shortcuts (including QT)
if (Test-Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Neovim\") {
    Remove-Item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Neovim\" -Recurse -Force
}

# Persist Environment Variables
[System.Environment]::SetEnvironmentVariable('WEZTERM_CONFIG_FILE', "$PSScriptRoot\wezterm\wezterm.lua", [System.EnvironmentVariableTarget]::User)

$currentGitEmail = (git config --global user.email)
$currentGitName = (git config --global user.name)

# Create Symbolic Links
Write-Host "Creating Symbolic Links..."
foreach ($symlink in $symlinks.GetEnumerator()) {
    Get-Item -Path $symlink.Key -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    New-Item -ItemType SymbolicLink -Path $symlink.Key -Target (Resolve-Path $symlink.Value) -Force | Out-Null
}

git config --global --unset user.email | Out-Null
git config --global --unset user.name | Out-Null
git config --global user.email $currentGitEmail | Out-Null
git config --global user.name $currentGitName | Out-Null

# Install bat themes
bat cache --clear
bat cache --build

.\altsnap\createTask.ps1 | Out-Null
