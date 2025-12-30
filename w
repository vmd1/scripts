# Windows PowerShell Script Menu for sc.vmd1.dev
param([string[]]$ShortCodes)

$scriptJsonUrl = "https://sc.vmd1.dev/scripts.json"
$tmpJson = "$env:TEMP\scripts.json"

try {
    Invoke-WebRequest -Uri $scriptJsonUrl -OutFile $tmpJson -UseBasicParsing
    $json = Get-Content $tmpJson | ConvertFrom-Json
} catch {
    Write-Host "Failed to download or parse scripts.json." -ForegroundColor Red
    exit
}

function Is-WindowsScript($script) {
    if ($null -eq $script.oses) { return $false }
    $oses = $script.oses
    if ($oses -is [string]) { $oses = @($oses) }
    foreach ($os in $oses) {
        if ($os.ToLower() -eq "windows") { return $true }
    }
    return $false
}

$winScripts = @()
foreach ($script in $json) {
    if (Is-WindowsScript $script) {
        $winScripts += $script
    }
}
if ($winScripts.Count -eq 0) {
    Write-Host "No Windows scripts available." -ForegroundColor Yellow
    Remove-Item $tmpJson -Force
    exit
}

# Headless mode: process short codes from parameters
if ($ShortCodes.Count -gt 0) {
    $validIdx = @()
    foreach ($code in $ShortCodes) {
        $found = $false
        for ($i = 0; $i -lt $winScripts.Count; $i++) {
            if ($winScripts[$i]."short-code" -eq $code) {
                $validIdx += $i
                $found = $true
                break
            }
        }
        if (-not $found) {
            Write-Host "Invalid short code: $code" -ForegroundColor Red
            Remove-Item $tmpJson -Force
            exit 1
        }
    }
    
    Write-Host "Running scripts:" -ForegroundColor Cyan
    foreach ($idx in $validIdx) {
        $script = $winScripts[$idx]
        Write-Host "Running $($script.name)..."
        Invoke-WebRequest -Uri $script.url -UseBasicParsing | Invoke-Expression
    }
    Remove-Item $tmpJson -Force
    exit 0
}

# Interactive mode
while ($true) {
    Write-Host "Available Windows Scripts:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $winScripts.Count; $i++) {
        Write-Host "$($i+1). $($winScripts[$i].name) [$($winScripts[$i]."short-code")]"
    }
    Write-Host "q. Quit"
    $choice = Read-Host "Select script(s) to run (number, short-code, or comma-separated list)"
    if ($choice -eq "q") { break }
    
    # Remove whitespace and split comma-separated selections
    $choice = $choice -replace '\s', ''
    $selections = $choice -split ','
    
    $validIdx = @()
    foreach ($item in $selections) {
        $item = $item.Trim()
        if ($item -match "^[0-9]+$" -and $item -ge 1 -and $item -le $winScripts.Count) {
            $validIdx += ($item - 1)
        } else {
            $found = $false
            for ($i = 0; $i -lt $winScripts.Count; $i++) {
                if ($winScripts[$i]."short-code" -eq $item) {
                    $validIdx += $i
                    $found = $true
                    break
                }
            }
            if (-not $found) {
                Write-Host "Invalid selection: $item" -ForegroundColor Red
            }
        }
    }
    
    if ($validIdx.Count -eq 0) {
        Write-Host "Invalid selection." -ForegroundColor Red
        Write-Host ""
        continue
    }
    
    Write-Host "`nSelected scripts:" -ForegroundColor Cyan
    foreach ($idx in $validIdx) {
        $script = $winScripts[$idx]
        Write-Host "$($idx+1). $($script.name) [$($script."short-code")]"
        Write-Host "   URL: $($script.url)"
    }
    
    $run = Read-Host "Run the selected script(s) now? (y/n)"
    if ($run -eq "y") {
        foreach ($idx in $validIdx) {
            $script = $winScripts[$idx]
            Write-Host "Running $($script.name)..." -ForegroundColor Green
            Invoke-WebRequest -Uri $script.url -UseBasicParsing | Invoke-Expression
        }
    }
    Write-Host ""
}
Remove-Item $tmpJson -Force
