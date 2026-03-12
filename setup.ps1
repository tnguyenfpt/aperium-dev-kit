<#
.SYNOPSIS
    Aperium Dev Kit - Bootstrap script for Windows.

.DESCRIPTION
    Sets up a target repository with the Aperium cross-agent consistency
    structure: copies AGENTS.md from the dev-kit template, creates symlinks
    (or falls back to copies) for each AI agent config file, ensures required
    directories exist, and appends standard .gitignore rules.

.PARAMETER RepoPath
    Path to the target repository root. Defaults to the current directory.

.EXAMPLE
    .\setup.ps1
    Bootstraps the current directory.

.EXAMPLE
    .\setup.ps1 -RepoPath C:\Dev\my-repo
    Bootstraps the specified repository.

.NOTES
    Symlink creation on Windows requires Developer Mode enabled or an
    elevated (Administrator) shell. If symlinks cannot be created, the script
    falls back to file copies with a warning.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$RepoPath,

    [switch]$Update
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

# Dev-kit root is the directory where this script lives.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DevKitRoot = $ScriptDir

# Target repo - use parameter or fall back to current location.
if (-not $RepoPath) {
    $RepoPath = (Get-Location).Path
    Write-Host "[info] No -RepoPath supplied; using current directory: $RepoPath" -ForegroundColor Cyan
}

$RepoPath = (Resolve-Path $RepoPath).Path

# Template paths
$AgentsTemplate    = Join-Path $ScriptDir 'AGENTS.md.template'
$GitignoreTemplate = Join-Path $ScriptDir '.gitignore.template'

if (-not (Test-Path $AgentsTemplate)) {
    Write-Host "[error] AGENTS.md.template not found at: $AgentsTemplate" -ForegroundColor Red
    exit 1
}

# Track whether we are using copies instead of real symlinks
$UsingCopies = $false

# ---------------------------------------------------------------------------
# Helper: track results for the summary
# ---------------------------------------------------------------------------

$Results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Add-Result {
    param(
        [string]$Step,
        [string]$Status,   # OK | WARN | FAIL
        [string]$Detail
    )
    $color = switch ($Status) {
        'OK'   { 'Green'  }
        'WARN' { 'Yellow' }
        'FAIL' { 'Red'    }
    }
    Write-Host "  [$Status] $Step - $Detail" -ForegroundColor $color
    $Results.Add([PSCustomObject]@{ Step = $Step; Status = $Status; Detail = $Detail })
}

# ---------------------------------------------------------------------------
# Helper: prompt before overwriting an existing file
# ---------------------------------------------------------------------------

function Confirm-Overwrite {
    param([string]$FilePath)

    if (Test-Path $FilePath) {
        $answer = Read-Host "  File already exists: $FilePath. Overwrite? (y/N)"
        if ($answer -notin @('y', 'Y', 'yes', 'Yes', 'YES')) {
            return $false
        }
    }
    return $true
}

# ---------------------------------------------------------------------------
# Helper: create a symlink with copy fallback
# ---------------------------------------------------------------------------

function New-SymlinkOrCopy {
    param(
        [string]$LinkPath,
        [string]$TargetRelative,   # relative target for the symlink
        [string]$SourceAbsolute    # absolute path to copy from if symlink fails
    )

    $stepName = (Split-Path $LinkPath -Leaf)

    # Prompt if the file already exists and is NOT already a symlink we created.
    if (Test-Path $LinkPath) {
        if (-not (Confirm-Overwrite $LinkPath)) {
            Add-Result $stepName 'WARN' 'Skipped - user chose not to overwrite'
            return
        }
        Remove-Item $LinkPath -Force
    }

    try {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetRelative -Force | Out-Null
        # Verify it is a real symlink
        $item = Get-Item $LinkPath
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Add-Result $stepName 'OK' "Symlink created -> $TargetRelative"
        }
        else {
            # ln succeeded but result is not a symlink (should not happen on PS)
            $script:UsingCopies = $true
            Add-Result $stepName 'WARN' "Copied (symlink verification failed - enable Developer Mode)"
        }
    }
    catch {
        Write-Host "  [warn] Symlink failed ($($_.Exception.Message)). Falling back to copy." -ForegroundColor Yellow
        $script:UsingCopies = $true
        try {
            Copy-Item -Path $SourceAbsolute -Destination $LinkPath -Force
            Add-Result $stepName 'WARN' "Copied (symlink unavailable - enable Developer Mode or run as Admin)"
        }
        catch {
            Add-Result $stepName 'FAIL' "Could not create symlink or copy: $($_.Exception.Message)"
        }
    }
}

# ---------------------------------------------------------------------------
# Step 1 - Copy AGENTS.md.template -> AGENTS.md and stamp version
# ---------------------------------------------------------------------------

Write-Host "`n=== Aperium Dev Kit - Bootstrap ===" -ForegroundColor Magenta
Write-Host "Dev-kit root : $DevKitRoot"
Write-Host "Target repo  : $RepoPath`n"

$AgentsDest = Join-Path $RepoPath 'AGENTS.md'

# BUG 5 fix: Resolve dev-kit git SHA for version stamping
$DevKitSha = 'unknown'
try {
    $sha = git -C $DevKitRoot rev-parse --short HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $sha) { $DevKitSha = $sha.Trim() }
}
catch { }

Write-Host "Step 1: Copy AGENTS.md template" -ForegroundColor White
if (-not (Confirm-Overwrite $AgentsDest)) {
    Add-Result 'AGENTS.md' 'WARN' 'Skipped - user chose not to overwrite'
}
else {
    try {
        Copy-Item -Path $AgentsTemplate -Destination $AgentsDest -Force
        # Replace {GIT_SHA} placeholder with actual commit hash
        $content = Get-Content $AgentsDest -Raw
        $content = $content -replace '\{GIT_SHA\}', $DevKitSha
        Set-Content -Path $AgentsDest -Value $content -Encoding UTF8 -NoNewline
        Add-Result 'AGENTS.md' 'OK' "Template copied (version: $DevKitSha)"
    }
    catch {
        Add-Result 'AGENTS.md' 'FAIL' $_.Exception.Message
    }
}

# ---------------------------------------------------------------------------
# Step 2 - Create required directories
# ---------------------------------------------------------------------------

Write-Host "`nStep 2: Ensure required directories exist" -ForegroundColor White

$Directories = @(
    (Join-Path $RepoPath '.github')
)

foreach ($dir in $Directories) {
    if (-not (Test-Path $dir)) {
        try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Add-Result $dir 'OK' 'Directory created'
        }
        catch {
            Add-Result $dir 'FAIL' $_.Exception.Message
        }
    }
    else {
        Add-Result $dir 'OK' 'Already exists'
    }
}

# ---------------------------------------------------------------------------
# Step 3 - Create symlinks (or copy fallback) for agent config files
# ---------------------------------------------------------------------------

Write-Host "`nStep 3: Create agent config symlinks" -ForegroundColor White

# Each entry: [link path relative to repo, symlink target relative to link location]
$Symlinks = @(
    @{
        LinkPath       = Join-Path $RepoPath 'CLAUDE.md'
        TargetRelative = 'AGENTS.md'
    },
    @{
        LinkPath       = Join-Path $RepoPath '.github' 'copilot-instructions.md'
        TargetRelative = '..\AGENTS.md'
    }
)

foreach ($link in $Symlinks) {
    New-SymlinkOrCopy `
        -LinkPath       $link.LinkPath `
        -TargetRelative $link.TargetRelative `
        -SourceAbsolute $AgentsDest
}

# Create specs/ directory
$SpecsDir = Join-Path $RepoPath 'specs'
if (-not (Test-Path $SpecsDir)) {
    New-Item -ItemType Directory -Path $SpecsDir -Force | Out-Null
    # Create .gitkeep so empty directory is tracked in git
    New-Item -ItemType File -Path (Join-Path $SpecsDir '.gitkeep') -Force | Out-Null
    Add-Result 'SpecsDir' 'OK' 'Created specs/ directory'
}

# ---------------------------------------------------------------------------
# Step 3b - Check for files already tracked by git (BUG 2 & 3 fix)
# ---------------------------------------------------------------------------

Write-Host "`nStep 3b: Check for git-tracked conflicts" -ForegroundColor White

$TrackedFiles = @()
$FilesToCheck = @('CLAUDE.md', '.github/copilot-instructions.md')

foreach ($f in $FilesToCheck) {
    try {
        $null = git -C $RepoPath ls-files --error-unmatch $f 2>$null
        if ($LASTEXITCODE -eq 0) {
            $TrackedFiles += $f
        }
    }
    catch { }
}

if ($TrackedFiles.Count -gt 0) {
    Write-Host "  [WARN] The following files are already tracked by git." -ForegroundColor Yellow
    Write-Host "  .gitignore rules will NOT take effect until they are untracked:" -ForegroundColor Yellow
    foreach ($f in $TrackedFiles) {
        Write-Host "    ->  git rm --cached $f" -ForegroundColor Yellow
    }
    Write-Host "  Then commit the removal before .gitignore rules apply." -ForegroundColor Yellow
    Add-Result 'Git tracking' 'WARN' "$($TrackedFiles.Count) file(s) already tracked - see above"
}
else {
    Add-Result 'Git tracking' 'OK' 'No conflicts with tracked files'
}

# ---------------------------------------------------------------------------
# Step 4 - Append .gitignore rules (agent-specific only if .gitignore exists)
# ---------------------------------------------------------------------------

Write-Host "`nStep 4: Append .gitignore rules" -ForegroundColor White

$GitignoreDest = Join-Path $RepoPath '.gitignore'

# BUG 4 fix: Minimal agent-specific rules for repos that already have a .gitignore
$AgentGitignoreBlock = @"

# --- Aperium Dev Kit: Agent Instructions ---
# AGENTS.md is the source of truth and MUST be tracked.
# These files are symlinks/copies managed by the dev-kit setup script.
CLAUDE.md
.github/copilot-instructions.md
# --- End Aperium Dev Kit ---
"@

if (-not (Test-Path $GitignoreTemplate)) {
    Add-Result '.gitignore' 'WARN' '.gitignore.template not found in dev-kit; skipped'
}
else {
    if (Test-Path $GitignoreDest) {
        $existingContent = Get-Content $GitignoreDest -Raw

        # Check for the sentinel comment that marks our block.
        if ($existingContent -match 'Aperium Dev Kit') {
            Add-Result '.gitignore' 'OK' 'Aperium rules already present; skipped'
        }
        else {
            # BUG 4 fix: Only append agent-specific rules, not the full template
            try {
                Add-Content -Path $GitignoreDest -Value $AgentGitignoreBlock -Encoding UTF8
                Add-Result '.gitignore' 'OK' 'Agent-specific rules appended (existing .gitignore preserved)'
            }
            catch {
                Add-Result '.gitignore' 'FAIL' $_.Exception.Message
            }
        }
    }
    else {
        # No .gitignore exists - use the full template
        try {
            $templateContent = Get-Content $GitignoreTemplate -Raw
            Set-Content -Path $GitignoreDest -Value $templateContent -Encoding UTF8
            Add-Result '.gitignore' 'OK' 'Created with full Aperium template'
        }
        catch {
            Add-Result '.gitignore' 'FAIL' $_.Exception.Message
        }
    }
}

# ---------------------------------------------------------------------------
# Update mode: refresh FIXED sections and copy updated skills/prompts
# ---------------------------------------------------------------------------

if ($Update) {
    Write-Host "`nRunning in update mode..." -ForegroundColor Magenta

    if (-not (Test-Path $AgentsDest)) {
        Add-Result 'Update' 'FAIL' 'AGENTS.md not found in target repo - run without -Update first'
    }
    else {
        # BUG 7 fix: Pre-parse template FIXED sections into indexed array.
        # This avoids the bug where identical FIXED markers always match the
        # first section instead of the correct one by position.
        $templateLines = Get-Content $AgentsTemplate
        $FixedSections = [System.Collections.Generic.List[string]]::new()
        $currentFixed = ''
        $inFixed = $false

        foreach ($tLine in $templateLines) {
            if ($tLine -match '<!-- FIXED:') {
                if ($inFixed -and $currentFixed) {
                    $FixedSections.Add($currentFixed)
                }
                $inFixed = $true
                $currentFixed = ''
            }
            elseif ($inFixed) {
                if ($tLine -match '<!-- CUSTOMIZABLE:' -or $tLine -match '<!-- aperium-dev-kit') {
                    $FixedSections.Add($currentFixed)
                    $inFixed = $false
                    $currentFixed = ''
                }
                else {
                    $currentFixed += "$tLine`n"
                }
            }
        }
        # Catch trailing FIXED section at EOF
        if ($inFixed -and $currentFixed) {
            $FixedSections.Add($currentFixed)
        }

        # Replace FIXED sections in target AGENTS.md by index order
        $targetLines = Get-Content $AgentsDest
        $outputLines = [System.Collections.Generic.List[string]]::new()
        $fixedIndex = 0
        $skipUntilNextMarker = $false

        foreach ($line in $targetLines) {
            if ($line -match '<!-- FIXED:') {
                $outputLines.Add($line)
                if ($fixedIndex -lt $FixedSections.Count) {
                    # Add each line from the pre-parsed section (trimming trailing newline)
                    $sectionContent = $FixedSections[$fixedIndex].TrimEnd("`n")
                    foreach ($sLine in ($sectionContent -split "`n")) {
                        $outputLines.Add($sLine)
                    }
                }
                $fixedIndex++
                $skipUntilNextMarker = $true
            }
            elseif ($skipUntilNextMarker) {
                if ($line -match '<!-- CUSTOMIZABLE:' -or $line -match '<!-- aperium-dev-kit') {
                    $skipUntilNextMarker = $false
                    $outputLines.Add($line)
                }
                elseif ($line -match '<!-- FIXED:') {
                    # Adjacent FIXED section
                    $outputLines.Add($line)
                    if ($fixedIndex -lt $FixedSections.Count) {
                        $sectionContent = $FixedSections[$fixedIndex].TrimEnd("`n")
                        foreach ($sLine in ($sectionContent -split "`n")) {
                            $outputLines.Add($sLine)
                        }
                    }
                    $fixedIndex++
                }
                # else skip old FIXED content
            }
            else {
                $outputLines.Add($line)
            }
        }

        try {
            $joined = ($outputLines -join "`n")
            # Stamp version
            $joined = $joined -replace '\{GIT_SHA\}', $DevKitSha
            Set-Content -Path $AgentsDest -Value $joined -Encoding UTF8 -NoNewline
            Add-Result 'FIXED sections' 'OK' "Updated from template (version: $DevKitSha)"
        }
        catch {
            Add-Result 'FIXED sections' 'FAIL' $_.Exception.Message
        }

        # Refresh copies if not using real symlinks
        if ($UsingCopies) {
            foreach ($f in $FilesToCheck) {
                $filePath = Join-Path $RepoPath $f
                if (Test-Path $filePath) {
                    $item = Get-Item $filePath
                    if (-not ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                        Copy-Item -Path $AgentsDest -Destination $filePath -Force
                    }
                }
            }
            Add-Result 'Copy refresh' 'OK' 'Refreshed agent config copies from updated AGENTS.md'
        }
    }

    # Copy updated skills
    $SkillsSrc = Join-Path $DevKitRoot 'skills'
    if (Test-Path $SkillsSrc) {
        $SkillsDest = Join-Path $RepoPath '.agents' 'skills'
        New-Item -ItemType Directory -Path $SkillsDest -Force | Out-Null
        try {
            Copy-Item -Path "$SkillsSrc\*" -Destination $SkillsDest -Recurse -Force
            Add-Result 'Skills' 'OK' 'Updated in .agents/skills/'
        }
        catch {
            Add-Result 'Skills' 'WARN' "Copy failed: $($_.Exception.Message)"
        }
    }

    # Copy updated prompt templates
    $PromptsSrc = Join-Path $DevKitRoot 'docs' 'prompts'
    if (Test-Path $PromptsSrc) {
        $PromptsDest = Join-Path $RepoPath 'docs' 'prompts'
        New-Item -ItemType Directory -Path $PromptsDest -Force | Out-Null
        try {
            Copy-Item -Path "$PromptsSrc\*" -Destination $PromptsDest -Recurse -Force
            Add-Result 'Prompts' 'OK' 'Updated in docs/prompts/'
        }
        catch {
            Add-Result 'Prompts' 'WARN' "Copy failed: $($_.Exception.Message)"
        }
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host "`n=== Summary ===" -ForegroundColor Magenta

$okCount   = ($Results | Where-Object Status -eq 'OK').Count
$warnCount = ($Results | Where-Object Status -eq 'WARN').Count
$failCount = ($Results | Where-Object Status -eq 'FAIL').Count

foreach ($r in $Results) {
    $color = switch ($r.Status) {
        'OK'   { 'Green'  }
        'WARN' { 'Yellow' }
        'FAIL' { 'Red'    }
    }
    Write-Host "  [$($r.Status)] $($r.Step) - $($r.Detail)" -ForegroundColor $color
}

Write-Host ""
Write-Host "Results: $okCount OK, $warnCount warnings, $failCount failures" -ForegroundColor $(
    if ($failCount -gt 0) { 'Red' } elseif ($warnCount -gt 0) { 'Yellow' } else { 'Green' }
)

# ---------------------------------------------------------------------------
# BUG 6 fix: Platform-aware next steps
# ---------------------------------------------------------------------------

Write-Host "`n=== Next Steps ===" -ForegroundColor Magenta
Write-Host "  1. Open AGENTS.md and fill in the {PLACEHOLDERS} in the customizable sections."
Write-Host "  2. Commit AGENTS.md and .gitignore to your repository."

if ($UsingCopies) {
    Write-Host "  3. NOTE: Agent config files are copies (not symlinks)." -ForegroundColor Yellow
    Write-Host "     After editing AGENTS.md, re-run with -Update to refresh copies." -ForegroundColor Yellow
    Write-Host "     To enable real symlinks: Settings > System > For developers > Developer Mode" -ForegroundColor Yellow
}
else {
    Write-Host "  3. Verify symlinks work:  Get-Item CLAUDE.md | Select-Object Target"
}

Write-Host ""

if ($failCount -gt 0) {
    exit 1
}
