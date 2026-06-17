#Requires -Version 5.1
<#
.SYNOPSIS
    Installer for git-ship on Windows.
.DESCRIPTION
    Downloads the git-ship script onto your PATH. git-ship is a Bash script, and
    Git for Windows bundles the Bash that runs it, so `git ship ...` works as a
    git subcommand from any shell (or open Git Bash). Install GitHub CLI (gh) so
    releases work without git-ship's python3 fallback.
.PARAMETER Dir
    Install directory (default: %LOCALAPPDATA%\git-ship).
.PARAMETER Ref
    Branch or tag to fetch the script from (default: main).
.PARAMETER NoModifyPath
    Don't edit your user PATH; just print guidance.
.EXAMPLE
    irm https://raw.githubusercontent.com/TimothyVang/git-ship/main/install.ps1 | iex
.EXAMPLE
    # download, inspect, then run with options:
    iwr https://raw.githubusercontent.com/TimothyVang/git-ship/main/install.ps1 -OutFile install.ps1
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Dir C:\tools\bin
#>
[CmdletBinding()]
param(
    [string]$Dir = (Join-Path $env:LOCALAPPDATA 'git-ship'),
    [string]$Ref = 'main',
    [switch]$NoModifyPath
)

$ErrorActionPreference = 'Stop'
$Repo = 'TimothyVang/git-ship'
$Src  = "https://raw.githubusercontent.com/$Repo/$Ref/git-ship"
$Dest = Join-Path $Dir 'git-ship'

function Write-GS { param([string]$Msg, [string]$Color = 'Gray') Write-Host "[git-ship] $Msg" -ForegroundColor $Color }

New-Item -ItemType Directory -Force -Path $Dir | Out-Null

Write-GS "downloading git-ship ($Ref) -> $Dest" 'Blue'
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Src -OutFile $Dest -UseBasicParsing
} catch {
    Write-GS "download failed from $Src" 'Red'
    throw
}
Write-GS "installed git-ship -> $Dest" 'Green'

# Add to the USER PATH, idempotently. Persists on Windows PowerShell 5.1 and 7.
if (-not $NoModifyPath) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @()
    if ($userPath) { $parts = @($userPath -split ';' | Where-Object { $_ -ne '' }) }
    if ($parts -notcontains $Dir) {
        $newPath = (@($parts + $Dir) -join ';')
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        $env:Path = "$env:Path;$Dir"
        Write-GS "added $Dir to your user PATH (open a NEW terminal to pick it up)" 'Green'
    }
    else {
        Write-GS "$Dir is already on your user PATH" 'Green'
    }
}
else {
    Write-GS "skipped PATH edit; add this directory to your user PATH yourself: $Dir" 'Yellow'
}

# Prerequisite nudges.
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-GS "git not found. Install Git for Windows (https://git-scm.com/download/win) - it bundles the Bash that runs git-ship." 'Yellow'
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-GS "no gh CLI found. Pushing works as-is; to cut releases install GitHub CLI (https://cli.github.com), then run: gh auth login" 'Yellow'
    Write-GS "(gh also avoids git-ship's python3 fallback, which Git Bash does not bundle.)" 'Yellow'
}

Write-Host ''
Write-GS "ready. git-ship is a Bash script - run it as a git subcommand from any shell, or from Git Bash:" 'Green'
Write-Host '    git ship --tag v1.0.0      # push current branch + cut a release'
Write-Host '    git ship -h                # all options'
