# ############################################################
#  Context Assembler — Windows + WSL
#
#  IMPORT syntax inside context.md:
#    [IMPORT] docs/somefile.md        → Windows (relative to script dir)
#    [IMPORT] wsl:src/app/page.tsx    → WSL     (relative to $WslProjectRoot)
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
Write-Host "[1/7] Script location: $scriptDir" -ForegroundColor DarkGray

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
Write-Host "[2/7] Configuration:" -ForegroundColor DarkGray
Write-Host "       Source:       $sourceFile" -ForegroundColor DarkGray
Write-Host "       Output:       $outputFile" -ForegroundColor DarkGray
Write-Host "       WSL Distro:   $WslDistro" -ForegroundColor DarkGray
Write-Host "       WSL Project:  $WslProjectRoot" -ForegroundColor DarkGray

# === STEP 2: Check source file exists ========================================
Write-Host ""
Write-Host "[3/7] Checking source file..." -ForegroundColor DarkGray

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
        Get-ChildItem $docsPath -Recurse -File | ForEach-Object {
            Write-Host "    $($_.FullName.Replace((Get-Location).Path + '\', ''))" -ForegroundColor Yellow
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

# === STEP 3: Check WSL connectivity ==========================================
Write-Host ""
Write-Host "[4/7] Checking WSL connectivity (distro: $WslDistro)..." -ForegroundColor DarkGray

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
$script:MissingFiles  = @()
$script:ImportCounter  = 0
$script:ImportSuccess  = 0

function Resolve-Imports($filePath, $depth) {
    if ($depth -eq $null) { $depth = 0 }
    $indent = "  " * $depth
    $script:ImportCounter++
    $importNum = $script:ImportCounter

    Write-Host "${indent}  [$importNum] Resolving: $filePath" -ForegroundColor DarkGray

    # ── WSL file ─────────────────────────────────────────────
    if ($filePath -match "^wsl:(.+)") {
        $wslRelPath  = $matches[1].Trim()
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

    # ── Process lines (recursive import resolution) ──────────
    $script:ImportSuccess++
    $processed = foreach ($line in $content) {
        if ($line -match "^\[IMPORT\]\s+(.+)") {
            Resolve-Imports ($matches[1].Trim()) ($depth + 1)
        }
        else {
            $line
        }
    }
    return $processed
}

# === STEP 5: Run assembly ====================================================
Write-Host ""
Write-Host "[5/7] Assembling (resolving imports)..." -ForegroundColor Cyan
Write-Host ""

$finalContent = Resolve-Imports $sourceFile 0

Write-Host ""
Write-Host "       Imports attempted: $($script:ImportCounter)" -ForegroundColor DarkGray
Write-Host "       Imports succeeded: $($script:ImportSuccess)" -ForegroundColor DarkGray
Write-Host "       Imports missing:   $($script:MissingFiles.Count)" -ForegroundColor DarkGray

# === STEP 6: Write output ====================================================
Write-Host ""
Write-Host "[6/7] Writing output..." -ForegroundColor DarkGray

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

# === STEP 7: Summary =========================================================
Write-Host ""
Write-Host "[7/7] Summary" -ForegroundColor Cyan
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