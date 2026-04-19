# ############################################################
#  Context Assembler — Windows + WSL
#
#  IMPORT syntax inside context.md:
#    [IMPORT] docs/somefile.md        → Windows (relative to script dir)
#    [IMPORT] wsl:src/app/page.tsx    → WSL     (relative to $WslProjectRoot)
#
#  SELECTIVE IMPORT syntax:
#    - [x] [IMPORT] docs/somefile.md  → Included (checkbox checked)
#    - [ ] [IMPORT] docs/somefile.md  → Skipped  (shows placeholder)
#
#  SECTION EXCLUSION syntax (line immediately after a heading):
#    ## My Section
#    INCLUDE_FAMILY: 1                → Section included, flag line removed
#
#    ## My Other Section
#    INCLUDE_FAMILY: 0                → Entire section + children excluded
#
#  WHOLE-FAMILY OVERRIDE (line after INCLUDE_FAMILY: 1):
#    ## My Section
#    INCLUDE_FAMILY: 1
#    INCLUDE_WHOLE_FAMILY: 1          → All child checkboxes forced on,
#                                       child INCLUDE_FAMILY flags ignored
#
#  AUTO-STRIPPED SECTIONS:
#    The "## Toggle Context Inclusion" section is automatically removed
#    from the assembled output (it is a source-only UI, not context).
#
#  PERFORMANCE:
#    WSL files are accessed via \\wsl.localhost\ (or \\wsl$\) UNC paths
#    when available, avoiding per-file wsl.exe process spawning.
#    Falls back to wsl.exe automatically if UNC is not accessible.
#
#  Run via:  assemble_context.bat  (double-click)
# ############################################################

# === STEP 0: Always keep the window open on crash ============================
trap {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "  UNHANDLED ERROR — SCRIPT CRASHED" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "  Location: $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim())" -ForegroundColor DarkRed
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor White
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Force PowerShell to use UTF-8 for external console output/input (Crucial for WSL)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# === STEP 1: Navigate to the script's own directory ==========================
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host ""
Write-Host "=== Context Assembler ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "[1/8] Script location: $scriptDir" -ForegroundColor DarkGray

try {
    Set-Location $scriptDir
    Write-Host "       Working dir set to: $(Get-Location)" -ForegroundColor DarkGray
}
catch {
    Write-Host "FATAL: Could not navigate to script directory: $scriptDir" -ForegroundColor Red
    Write-Host "       Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor White
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# --- Configuration -----------------------------------------------------------
$sourceFile     = "context.md"
$outputFile     = "cc.md"
$WslDistro      = "Ubuntu"
$WslProjectRoot = "/home/zimablue/univalence-gravity"
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "[2/8] Configuration:" -ForegroundColor DarkGray
Write-Host "       Source:       $sourceFile" -ForegroundColor DarkGray
Write-Host "       Output:       $outputFile" -ForegroundColor DarkGray
Write-Host "       WSL Distro:   $WslDistro" -ForegroundColor DarkGray
Write-Host "       WSL Project:  $WslProjectRoot" -ForegroundColor DarkGray

# === STEP 2: Check source file exists ========================================
Write-Host ""
Write-Host "[3/8] Checking source file..." -ForegroundColor DarkGray

$sourceFullPath = Join-Path (Get-Location) $sourceFile
Write-Host "       Resolved path: $sourceFullPath" -ForegroundColor DarkGray

if (-not (Test-Path $sourceFile)) {
    Write-Host ""
    Write-Host "FATAL: Source file not found!" -ForegroundColor Red
    Write-Host "  Expected at: $sourceFullPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Contents of $(Get-Location):" -ForegroundColor Yellow
    Get-ChildItem -Force | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor Yellow }
    Write-Host ""

    $docsPath = Join-Path (Get-Location) "docs"
    if (Test-Path $docsPath) {
        Write-Host "  Contents of docs/:" -ForegroundColor Yellow
        $cwdPrefix = [regex]::Escape((Get-Location).Path + '\')
        Get-ChildItem $docsPath -Recurse -File | ForEach-Object {
            Write-Host "    $($_.FullName -replace $cwdPrefix, '')" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  'docs/' folder does not exist either." -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor White
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
Write-Host "       Found." -ForegroundColor Green

# === STEP 3: Check WSL connectivity + probe UNC fast-path ====================
Write-Host ""
Write-Host "[4/8] Checking WSL connectivity (distro: $WslDistro)..." -ForegroundColor DarkGray

$script:WslUncBase = $null      # non-null when UNC fast-path is available

try {
    $wslCheck = wsl -d $WslDistro -- echo OK 2>&1
    Write-Host "       WSL responded: '$wslCheck'" -ForegroundColor DarkGray

    if ($wslCheck -ne "OK") {
        Write-Host ""
        Write-Host "WARNING: WSL distro '$WslDistro' did not respond with 'OK'." -ForegroundColor Yellow
        Write-Host "         Response was: '$wslCheck'" -ForegroundColor Yellow
        Write-Host "         WSL imports will likely fail." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Available WSL distros:" -ForegroundColor Yellow
        wsl --list --verbose 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        Write-Host ""
        Write-Host "Press any key to continue anyway (or Ctrl+C to abort)..." -ForegroundColor White
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    else {
        Write-Host "       WSL OK." -ForegroundColor Green

        # --- Probe UNC filesystem path ----------------------------------------
        Write-Host ""
        Write-Host "       Probing UNC path for direct filesystem access..." -ForegroundColor DarkGray

        $wslProjectPathWin = $WslProjectRoot -replace '/', '\'
        $uncCandidates = @(
            ('\\wsl.localhost\' + $WslDistro + $wslProjectPathWin),
            ('\\wsl$\'          + $WslDistro + $wslProjectPathWin)
        )

        foreach ($candidate in $uncCandidates) {
            Write-Host "         Trying: $candidate" -ForegroundColor DarkGray
            if (Test-Path -LiteralPath $candidate) {
                $script:WslUncBase = $candidate
                break
            }
        }

        if ($script:WslUncBase) {
            Write-Host "       UNC base: $($script:WslUncBase)" -ForegroundColor Green
            Write-Host "       (WSL files will be read natively — no per-file wsl.exe spawn)" -ForegroundColor Green
        }
        else {
            Write-Host "       UNC path not available — falling back to wsl.exe per-file." -ForegroundColor Yellow
            Write-Host "       (Functional, but slower.  Requires Win 10 1903+ with WSL.)" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host ""
    Write-Host "WARNING: Could not reach WSL at all." -ForegroundColor Yellow
    Write-Host "         Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "         WSL imports will fail. Windows imports will still work." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to continue anyway (or Ctrl+C to abort)..." -ForegroundColor White
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# === STEP 4: Define the resolver =============================================
$script:MissingFiles     = @()
$script:ImportCounter     = 0
$script:ImportSuccess     = 0
$script:ExcludedSections  = 0

function Resolve-Imports($filePath, $depth) {
    if ($depth -eq $null) { $depth = 0 }
    $indent = "  " * $depth
    $script:ImportCounter++
    $importNum = $script:ImportCounter

    Write-Host "${indent}  [$importNum] Resolving: $filePath" -ForegroundColor DarkGray

    # ── WSL file ─────────────────────────────────────────────
    if ($filePath -match "^wsl:(.+)") {
        $wslRelPath = $matches[1].Trim()

        # ── Fast path: native read via UNC (no process spawn) ────────
        if ($script:WslUncBase) {
            $wslRelPathWin = $wslRelPath -replace '/', '\'
            $fullUncPath   = Join-Path $script:WslUncBase $wslRelPathWin
            Write-Host "${indent}       (UNC) $fullUncPath" -ForegroundColor DarkGray

            if (-not (Test-Path -LiteralPath $fullUncPath)) {
                Write-Host "${indent}       NOT FOUND." -ForegroundColor Yellow
                $script:MissingFiles += "$filePath  ->  UNC:$fullUncPath (Not Found)"
                return "*(Document not yet developed: $filePath)*"
            }

            try {
                $content = @(Get-Content -LiteralPath $fullUncPath -Encoding UTF8)
            }
            catch {
                Write-Host "${indent}       ERROR reading via UNC: $($_.Exception.Message)" -ForegroundColor Red
                $script:MissingFiles += "$filePath  ->  UNC:$fullUncPath (Read Error: $($_.Exception.Message))"
                return "*(Error reading WSL file: $filePath)*"
            }

            if ($content.Count -eq 0) {
                Write-Host "${indent}       EMPTY." -ForegroundColor Yellow
                $script:MissingFiles += "$filePath  ->  UNC:$fullUncPath (Empty)"
                return "*(Document not yet developed: $filePath is empty)*"
            }

            Write-Host "${indent}       Read $($content.Count) lines." -ForegroundColor DarkGray
        }
        # ── Slow fallback: wsl.exe per-file ──────────────────────────
        else {
            $wslFullPath = "$WslProjectRoot/$wslRelPath"
            Write-Host "${indent}       (WSL) Full path: $wslFullPath" -ForegroundColor DarkGray

            try {
                $exists = wsl -d $WslDistro -- bash -c "test -f '$wslFullPath' && echo YES || echo NO" 2>&1
                Write-Host "${indent}       Exists check: '$exists'" -ForegroundColor DarkGray
            }
            catch {
                Write-Host "${indent}       ERROR running WSL existence check: $($_.Exception.Message)" -ForegroundColor Red
                $script:MissingFiles += "$filePath  ->  WSL:$wslFullPath (WSL Error: $($_.Exception.Message))"
                return "*(Error reading WSL file: $filePath)*"
            }

            if ($exists -ne "YES") {
                Write-Host "${indent}       NOT FOUND." -ForegroundColor Yellow
                $script:MissingFiles += "$filePath  ->  WSL:$wslFullPath (Not Found)"
                return "*(Document not yet developed: $filePath)*"
            }

            try {
                $content = @(wsl -d $WslDistro -- bash -c "cat '$wslFullPath'" 2>&1)
            }
            catch {
                Write-Host "${indent}       ERROR reading WSL file: $($_.Exception.Message)" -ForegroundColor Red
                $script:MissingFiles += "$filePath  ->  WSL:$wslFullPath (Read Error)"
                return "*(Error reading WSL file: $filePath)*"
            }

            if ($content.Count -eq 0 -or ($content.Count -eq 1 -and [string]::IsNullOrWhiteSpace($content[0]))) {
                Write-Host "${indent}       EMPTY." -ForegroundColor Yellow
                $script:MissingFiles += "$filePath  ->  WSL:$wslFullPath (Empty)"
                return "*(Document not yet developed: $filePath is empty)*"
            }

            Write-Host "${indent}       Read $($content.Count) lines." -ForegroundColor DarkGray
        }
    }
    # ── Windows file ─────────────────────────────────────────
    else {
        $resolvedWinPath = Join-Path (Get-Location) $filePath
        Write-Host "${indent}       (WIN) Resolved: $resolvedWinPath" -ForegroundColor DarkGray

        if (-not (Test-Path $filePath)) {
            Write-Host "${indent}       NOT FOUND." -ForegroundColor Yellow
            $script:MissingFiles += "$filePath  ->  $resolvedWinPath (Not Found)"
            return "*(Document not yet developed: $filePath)*"
        }

        try {
            $content = @(Get-Content -Path $filePath -Encoding UTF8)
        }
        catch {
            Write-Host "${indent}       ERROR reading file: $($_.Exception.Message)" -ForegroundColor Red
            $script:MissingFiles += "$filePath  ->  $resolvedWinPath (Read Error: $($_.Exception.Message))"
            return "*(Error reading file: $filePath)*"
        }

        if ($content.Count -eq 0) {
            Write-Host "${indent}       EMPTY." -ForegroundColor Yellow
            $script:MissingFiles += "$filePath  ->  $resolvedWinPath (Empty)"
            return "*(Document not yet developed: $filePath is empty)*"
        }

        Write-Host "${indent}       Read $($content.Count) lines." -ForegroundColor DarkGray
    }

    # ── Process lines (section filtering + recursive import resolution) ──────
    $script:ImportSuccess++
    $result = New-Object System.Collections.Generic.List[string]

    $i = 0
    $skipUntilLevel = -1          # -1 = not skipping; >=1 = skip everything until
                                  # a heading of this level or shallower is found
    $forceIncludeUntilLevel = -1  # -1 = not forcing; >=1 = import every document
                                  # (ignore checkboxes & child flags) until a heading
                                  # of this level or shallower is found

    while ($i -lt $content.Count) {
        $line = $content[$i]

        # ── Heading detection ────────────────────────────────────────
        if ($line -match '^(#{1,6})\s') {
            $headingLevel = $matches[1].Length

            # Check whether this heading ends the force-include zone
            if ($forceIncludeUntilLevel -ge 0 -and $headingLevel -le $forceIncludeUntilLevel) {
                $forceIncludeUntilLevel = -1
            }

            # If we are inside an excluded section, check whether
            # this heading is shallow enough to end the skip zone.
            if ($skipUntilLevel -ge 0) {
                if ($headingLevel -le $skipUntilLevel) {
                    $skipUntilLevel = -1          # stop skipping
                }
                else {
                    $i++; continue                # deeper sub-heading → still excluded
                }
            }

            # ── Inside a force-include zone ──────────────────────────
            # Sub-section flags are irrelevant — consume them silently
            # and keep processing content with forced imports.
            if ($forceIncludeUntilLevel -ge 0) {
                $result.Add($line)                # emit the sub-heading itself
                $j = $i + 1
                # skip blank lines
                while ($j -lt $content.Count -and $content[$j].Trim() -eq '') { $j++ }
                # consume INCLUDE_FAMILY line if present
                if ($j -lt $content.Count -and
                    $content[$j] -match '^\s*INCLUDE_FAMILY\s*:\s*[01]\s*$') {
                    $j++
                    while ($j -lt $content.Count -and $content[$j].Trim() -eq '') { $j++ }
                    # consume INCLUDE_WHOLE_FAMILY line if present
                    if ($j -lt $content.Count -and
                        $content[$j] -match '^\s*INCLUDE_WHOLE_FAMILY\s*:\s*[01]\s*$') {
                        $j++
                    }
                }
                $i = $j; continue
            }

            # ── Normal flag look-ahead ───────────────────────────────
            # Skip past blank lines after the heading
            $j = $i + 1
            while ($j -lt $content.Count -and $content[$j].Trim() -eq '') { $j++ }

            if ($j -lt $content.Count -and
                $content[$j] -match '^\s*INCLUDE_FAMILY\s*:\s*([01])\s*$') {

                $familyFlag = [int]$matches[1]

                # Look for INCLUDE_WHOLE_FAMILY on the next non-blank line
                $k = $j + 1
                while ($k -lt $content.Count -and $content[$k].Trim() -eq '') { $k++ }

                $wholeFamilyFlag = 0
                $consumeUpTo = $j + 1            # just past INCLUDE_FAMILY

                if ($k -lt $content.Count -and
                    $content[$k] -match '^\s*INCLUDE_WHOLE_FAMILY\s*:\s*([01])\s*$') {
                    $wholeFamilyFlag = [int]$matches[1]
                    $consumeUpTo = $k + 1         # also past INCLUDE_WHOLE_FAMILY
                }

                if ($familyFlag -eq 0) {
                    # ── EXCLUDE entire section (INCLUDE_FAMILY dominates) ──
                    $skipUntilLevel = $headingLevel
                    $script:ExcludedSections++
                    Write-Host "${indent}       EXCLUDED section (INCLUDE_FAMILY:0): $($line.Trim())" -ForegroundColor DarkYellow
                    $i++; continue
                }
                else {
                    # ── INCLUDE section ──
                    $result.Add($line)            # emit heading

                    if ($wholeFamilyFlag -eq 1) {
                        # Force-import everything until a heading of this
                        # level or shallower is encountered
                        $forceIncludeUntilLevel = $headingLevel
                        Write-Host "${indent}       FORCE-INCLUDE zone (INCLUDE_WHOLE_FAMILY:1): $($line.Trim())" -ForegroundColor DarkGreen
                    }

                    $i = $consumeUpTo; continue   # skip past consumed flag lines
                }
            }
            else {
                # No INCLUDE_FAMILY flag after heading → pass through unchanged
                $result.Add($line)
                $i++; continue
            }
        }

        # ── General skip guard ───────────────────────────────────────
        if ($skipUntilLevel -ge 0) {
            $i++; continue
        }

        # ── Stray INCLUDE_FAMILY line (safety net) ───────────────────
        if ($line -match '^\s*INCLUDE_FAMILY\s*:\s*[01]\s*$') {
            $i++; continue
        }

        # ── Stray INCLUDE_WHOLE_FAMILY line (safety net) ─────────────
        if ($line -match '^\s*INCLUDE_WHOLE_FAMILY\s*:\s*[01]\s*$') {
            $i++; continue
        }

        # ── Look-ahead / look-behind for ~~~~ around unchecked imports ───
        $nextLine = if ($i + 1 -lt $content.Count) { $content[$i+1] } else { $null }
        $prevLine = if ($i -gt 0) { $content[$i-1] } else { $null }

        # skip ~~~~ before an unchecked checkbox import (only when NOT force-including)
        if ($line -match "^~~~~" -and $nextLine -match "^\s*-\s*\[\s\]\s*\[IMPORT\]" -and $forceIncludeUntilLevel -lt 0) {
            $i++; continue
        }

        # skip ~~~~ after an unchecked checkbox import (only when NOT force-including)
        if ($line -match "^~~~~" -and $prevLine -match "^\s*-\s*\[\s\]\s*\[IMPORT\]" -and $forceIncludeUntilLevel -lt 0) {
            $i++; continue
        }

        # ── Checkbox import ──────────────────────────────────────────
        if ($line -match "^\s*-\s*\[([xX\s])\]\s*\[IMPORT\]\s+(.+)") {
            $checkboxState = $matches[1]
            $importPath    = $matches[2].Trim()

            if ($checkboxState -match "[xX]" -or $forceIncludeUntilLevel -ge 0) {
                # Checked (or forced by INCLUDE_WHOLE_FAMILY): include the imported content
                $result.AddRange([string[]]@(Resolve-Imports $importPath ($depth + 1)))
            } else {
                # Unchecked: show placeholder, skip the import
                Write-Host "${indent}       SKIPPED (unchecked): $importPath" -ForegroundColor DarkYellow
                $result.Add("*(Content hidden due to context length)*")
            }
            $i++; continue
        }

        # ── Plain [IMPORT] (always include) ──────────────────────────
        if ($line -match "^\[IMPORT\]\s+(.+)") {
            $importPath = $matches[1].Trim()
            $result.AddRange([string[]]@(Resolve-Imports $importPath ($depth + 1)))
            $i++; continue
        }

        # ── Ordinary line ────────────────────────────────────────────
        $result.Add($line)
        $i++
    }

    return $result
}

# === STEP 5: Run assembly ====================================================
Write-Host ""
Write-Host "[5/8] Assembling (resolving imports)..." -ForegroundColor Cyan
if ($script:WslUncBase) {
    Write-Host "       Using UNC fast-path for WSL files." -ForegroundColor DarkGray
} else {
    Write-Host "       Using wsl.exe fallback for WSL files." -ForegroundColor DarkGray
}
Write-Host ""

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$finalContent = Resolve-Imports $sourceFile 0

$stopwatch.Stop()

Write-Host ""
Write-Host "       Imports attempted:  $($script:ImportCounter)" -ForegroundColor DarkGray
Write-Host "       Imports succeeded:  $($script:ImportSuccess)" -ForegroundColor DarkGray
Write-Host "       Imports missing:    $($script:MissingFiles.Count)" -ForegroundColor DarkGray
Write-Host "       Sections excluded:  $($script:ExcludedSections)" -ForegroundColor DarkGray
Write-Host "       Assembly time:      $($stopwatch.Elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor DarkGray

# === STEP 6: Strip "Toggle Context Inclusion" section =========================
#
#  This section is a source-only UI for controlling which families to include.
#  It should never appear in the assembled output.  We remove everything from
#  the "## Toggle Context Inclusion" heading up to (but not including) the
#  next heading of equal or shallower depth (## or #).
# =============================================================================
Write-Host ""
Write-Host "[6/8] Stripping '## Toggle Context Inclusion' section..." -ForegroundColor DarkGray

$stripped     = New-Object System.Collections.Generic.List[string]
$skipping     = $false
$linesRemoved = 0

foreach ($line in $finalContent) {
    # Detect the start of the toggle section (exact level-2 heading)
    if (-not $skipping -and $line -match '^\s*##\s+Toggle Context Inclusion\s*$') {
        $skipping = $true
        $linesRemoved++
        continue
    }

    if ($skipping) {
        # Stop skipping when we hit a heading of level 1 or 2 (i.e. # or ##)
        if ($line -match '^#{1,2}\s') {
            $skipping = $false
            $stripped.Add($line)
        }
        else {
            $linesRemoved++
        }
        continue
    }

    $stripped.Add($line)
}

$finalContent = $stripped

if ($linesRemoved -gt 0) {
    Write-Host "       Removed $linesRemoved lines." -ForegroundColor Green
}
else {
    Write-Host "       Section not found (nothing to remove)." -ForegroundColor DarkGray
}

# === STEP 7: Write output ====================================================
Write-Host ""
Write-Host "[7/8] Writing output..." -ForegroundColor DarkGray

try {
    $outDir = Split-Path $outputFile -Parent
    if ($outDir -and -not (Test-Path $outDir)) {
        Write-Host "       Creating directory: $outDir" -ForegroundColor DarkGray
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    $absoluteOut = Join-Path (Get-Location) $outputFile
    $cleanText   = $finalContent -join "`r`n"
    [IO.File]::WriteAllText($absoluteOut, $cleanText, [System.Text.UTF8Encoding]::new($false))

    $sizeKB = [math]::Round((Get-Item $absoluteOut).Length / 1024, 1)
    Write-Host "       Written to: $absoluteOut ($sizeKB KB)" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "FATAL: Failed to write output file!" -ForegroundColor Red
    Write-Host "       Path: $absoluteOut" -ForegroundColor Red
    Write-Host "       Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor White
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# === STEP 8: Summary =========================================================
Write-Host ""
Write-Host "[8/8] Summary" -ForegroundColor Cyan
Write-Host ""

if ($script:MissingFiles.Count -gt 0) {
    Write-Host "--- INCOMPLETE DOCUMENTS ---" -ForegroundColor Yellow
    foreach ($file in $script:MissingFiles) {
        Write-Host "  [-] $file" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "$outputFile generated with placeholders." -ForegroundColor Gray
}
else {
    Write-Host "All imports resolved successfully." -ForegroundColor Green
    Write-Host "$outputFile generated." -ForegroundColor Green
}

# === ALWAYS pause at the end ==================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Done. Press any key to close." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")