#Requires -Version 5.1
<#
.SYNOPSIS
    SPADE Framework — Setup Script (Windows)

.DESCRIPTION
    Installs exact SPADE capability projections for Claude, Codex, or both.

.EXAMPLE
    .\setup.ps1 -HostTarget all

.NOTES
    After running this, use /spade-onboard in either supported host.
#>

param(
    [ValidateSet('claude', 'codex', 'all')]
    [string]$HostTarget = 'all'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$CapabilityFile = Join-Path $ScriptDir 'src\CAPABILITIES.md'
$VersionLine = Select-String -Path $CapabilityFile -Pattern '^version:\s*(.+)$' | Select-Object -First 1
if (-not $VersionLine) { throw 'Missing version in src/CAPABILITIES.md' }
$Version = $VersionLine.Matches[0].Groups[1].Value.Trim()
$CanonicalLine = Select-String -Path $CapabilityFile -Pattern '^canonical_remote:\s*(.+)$' | Select-Object -First 1
if (-not $CanonicalLine) { throw 'Missing canonical remote in src/CAPABILITIES.md' }
$CanonicalRemote = $CanonicalLine.Matches[0].Groups[1].Value.Trim()

# --- Output helpers ---

function Write-Header {
    Write-Host ''
    Write-Host ([string][char]0x2501 * 52) -ForegroundColor Blue
    Write-Host "  SPADE Framework v${Version}" -ForegroundColor Blue
    Write-Host '  A Human-AI Operating Model for Engineering Teams' -ForegroundColor Blue
    Write-Host ([string][char]0x2501 * 52) -ForegroundColor Blue
    Write-Host ''
}

function Write-OK   { param([string]$Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Info  { param([string]$Msg) Write-Host " ->  $Msg" -ForegroundColor Blue }

function Assert-SafeRelativePath {
    <# Validates one manifest path before it can reach the filesystem. #>
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or [IO.Path]::IsPathRooted($Path) -or $Path.Contains('..') -or $Path.Contains('\')) {
        throw "Unsafe manifest path: $Path"
    }
}

function Assert-NoReparseComponents {
    <# Rejects symlink or junction components beneath HOME. #>
    param([string]$RelativePath)
    $Current = $HOME
    if ((Get-Item -LiteralPath $Current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw 'HOME is a reparse point; refusing install'
    }
    foreach ($Component in $RelativePath.Split('/')) {
        if (-not $Component) { continue }
        $Current = Join-Path $Current $Component
        if (Test-Path -LiteralPath $Current) {
            $Item = Get-Item -LiteralPath $Current -Force
            if ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Reparse-point destination component: $Current"
            }
        }
    }
}

function Read-InstallManifest {
    <# Parses and fully validates one exact host manifest before mutation. #>
    param([string]$HostName)
    $ManifestPath = Join-Path $ScriptDir "generated\install\$HostName.manifest"
    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) { throw "Missing install manifest: $ManifestPath" }
    $Records = @()
    foreach ($Line in Get-Content -LiteralPath $ManifestPath) {
        $Parts = $Line.Split('|')
        if ($Parts.Count -ne 4 -or $Parts[0] -ne 'file' -or $Parts[3] -notmatch '^[0-9a-f]{64}$') { throw "Malformed manifest line: $Line" }
        Assert-SafeRelativePath $Parts[1]
        Assert-SafeRelativePath $Parts[2]
        $Source = Join-Path $ScriptDir ($Parts[1].Replace('/', '\'))
        if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Missing source: $($Parts[1])" }
        if ((Get-Item -LiteralPath $Source -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Symlink source: $Source" }
        if ((Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Parts[3]) { throw "Source digest mismatch: $($Parts[1])" }
        Assert-NoReparseComponents $Parts[2]
        $Records += [pscustomobject]@{ SourceRel = $Parts[1]; DestinationRel = $Parts[2]; Source = $Source; Digest = $Parts[3] }
    }
    return $Records
}

function Remove-StaleOwnedEntries {
    <# Removes only undeclared spade-prefixed entries inside the selected host roots. #>
    param([string]$HostName, [array]$Records)
    $Patterns = if ($HostName -eq 'claude') {
        @('.claude\skills\spade*', '.claude\skills\leads', '.claude\skills\unslop', '.claude\agents\spade-*.md', '.spade\bin\spade-*')
    } else {
        @('.codex\skills\spade*', '.codex\skills\leads', '.codex\skills\unslop', '.spade\bin\spade-*')
    }
    foreach ($Pattern in $Patterns) {
        $Parent = Join-Path $HOME (Split-Path $Pattern -Parent)
        $Leaf = Split-Path $Pattern -Leaf
        if (-not (Test-Path -LiteralPath $Parent -PathType Container)) { continue }
        foreach ($Candidate in Get-ChildItem -LiteralPath $Parent -Filter $Leaf -Force) {
            if ($Candidate.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Refusing stale reparse point: $($Candidate.FullName)" }
            $Relative = $Candidate.FullName.Substring($HOME.Length + 1).Replace('\', '/')
            $Declared = $Records | Where-Object { $_.DestinationRel -eq $Relative -or $_.DestinationRel.StartsWith("$Relative/") }
            if (-not $Declared) {
                Remove-Item -LiteralPath $Candidate.FullName -Recurse -Force
                Write-Info "Removed stale SPADE-owned entry: $Relative"
            } elseif ($Candidate.PSIsContainer) {
                foreach ($Nested in Get-ChildItem -LiteralPath $Candidate.FullName -Recurse -Force) {
                    if ($Nested.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Refusing nested reparse point: $($Nested.FullName)" }
                    if ($Nested.PSIsContainer) { continue }
                    $NestedRelative = $Nested.FullName.Substring($HOME.Length + 1).Replace('\', '/')
                    $NestedDeclared = $Records | Where-Object { $_.DestinationRel -eq $NestedRelative }
                    if (-not $NestedDeclared) {
                        Remove-Item -LiteralPath $Nested.FullName -Force
                        Write-Info "Removed stale SPADE-owned file: $NestedRelative"
                    }
                }
                Get-ChildItem -LiteralPath $Candidate.FullName -Directory -Recurse -Force |
                    Sort-Object { $_.FullName.Length } -Descending |
                    ForEach-Object {
                        if (-not (Get-ChildItem -LiteralPath $_.FullName -Force)) {
                            Remove-Item -LiteralPath $_.FullName -Force
                        }
                    }
            }
        }
    }
}

function Install-HostManifest {
    <# Installs one host after full validation and verifies every declared file. #>
    param([string]$HostName)
    $Records = @(Read-InstallManifest $HostName)
    $SourceIsGlobalClone = [IO.Path]::GetFullPath($ScriptDir).TrimEnd('\') -eq [IO.Path]::GetFullPath((Join-Path $HOME '.spade')).TrimEnd('\')
    Remove-StaleOwnedEntries $HostName $Records
    foreach ($Record in $Records) {
        $Destination = Join-Path $HOME ($Record.DestinationRel.Replace('/', '\'))
        if ($SourceIsGlobalClone -and $Record.DestinationRel -eq '.spade/CAPABILITIES.md') { continue }
        if ([IO.Path]::GetFullPath($Record.Source).TrimEnd('\') -eq [IO.Path]::GetFullPath($Destination).TrimEnd('\')) {
            continue
        }
        $Parent = Split-Path $Destination -Parent
        New-Item -Path $Parent -ItemType Directory -Force | Out-Null
        Copy-Item -LiteralPath $Record.Source -Destination $Destination -Force
    }
    foreach ($Record in $Records) {
        $Destination = Join-Path $HOME ($Record.DestinationRel.Replace('/', '\'))
        if ($SourceIsGlobalClone -and $Record.DestinationRel -eq '.spade/CAPABILITIES.md') { continue }
        if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) { throw "Installed manifest mismatch: $($Record.DestinationRel)" }
        $SourceHash = (Get-FileHash -LiteralPath $Record.Source -Algorithm SHA256).Hash
        $DestinationHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
        if ($SourceHash -ne $DestinationHash -or $DestinationHash.ToLowerInvariant() -ne $Record.Digest) { throw "Installed content mismatch: $($Record.DestinationRel)" }
    }
    $ReceiptDir = Join-Path $HOME '.config\spade'
    New-Item -Path $ReceiptDir -ItemType Directory -Force | Out-Null
    $Approved = $env:SPADE_APPROVED_SHA
    $Status = 'unverified'
    $Revision = ''
    $SourceRemote = ''
    if ($Approved) {
        if ($Approved -notmatch '^[0-9a-f]{40,64}$') { throw 'SPADE_APPROVED_SHA must be an exact commit' }
        $Top = (& git -C $ScriptDir rev-parse --show-toplevel 2>$null | Select-Object -First 1)
        if ($LASTEXITCODE -ne 0 -or [IO.Path]::GetFullPath($Top).TrimEnd('\') -ne [IO.Path]::GetFullPath($ScriptDir).TrimEnd('\')) { throw 'Approved setup source is not a Git root' }
        $Revision = (& git -C $ScriptDir rev-parse HEAD 2>$null | Select-Object -First 1)
        $SourceRemote = (& git -C $ScriptDir remote get-url origin 2>$null | Select-Object -First 1)
        $Dirty = (& git -C $ScriptDir status --porcelain 2>$null) -join ''
        if ($Revision -ne $Approved) { throw 'Approved setup SHA does not equal source HEAD' }
        if ($SourceRemote -ne $CanonicalRemote) { throw 'Approved setup source is not the canonical remote' }
        if ($Dirty) { throw 'Approved setup source is dirty' }
        $Status = 'approved-commit'
    }
    $Receipt = Join-Path $ReceiptDir "$HostName.manifest"
    Set-Content -LiteralPath $Receipt -Value "provenance|$Status|$Revision|$SourceRemote|$Version" -Encoding ascii
    Get-Content -LiteralPath (Join-Path $ScriptDir "generated\install\$HostName.manifest") | Add-Content -LiteralPath $Receipt -Encoding ascii
    Write-OK "$HostName global projection installed"
}

# --- Main ---

Write-Header

Write-Host "Installing SPADE global projections for: $HostTarget"
Write-Host ''
if ($HostTarget -eq 'claude' -or $HostTarget -eq 'all') { Install-HostManifest 'claude' }
if ($HostTarget -eq 'codex' -or $HostTarget -eq 'all') { Install-HostManifest 'codex' }

Write-Host ''
Write-OK 'Global projections installed and verified.'
Write-Host ''
Write-Host ([string][char]0x2501 * 52) -ForegroundColor Green
Write-Host '  SPADE installed successfully.' -ForegroundColor Green
Write-Host ([string][char]0x2501 * 52) -ForegroundColor Green
Write-Host ''
Write-Host 'Next steps:'
Write-Host ''
Write-Host '  1. Open Claude Code or Codex in any project'
Write-Host '  2. Run /spade-onboard to initialise SPADE and fill in architecture docs'
Write-Host '  3. Commit the generated files so your team gets SPADE automatically'
Write-Host ''
