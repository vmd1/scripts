# Windows PowerShell Script Menu for sc.vmd1.dev
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

while ($true) {
    Write-Host "Available Windows Scripts:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $winScripts.Count; $i++) {
        Write-Host "$($i+1). $($winScripts[$i].name)"
    }
    Write-Host "q. Quit"
    $choice = Read-Host "Select a script to view details or run (number or comma-separated list)"
    if ($choice -eq "q") { break }

    # Remove whitespace and split on commas
    $choice = $choice -replace '\s',''
    $selected = $choice -split ','

    $validIdx = @()
    foreach ($item in $selected) {
        if ($item -match '^[0-9]+$' -and [int]$item -ge 1 -and [int]$item -le $winScripts.Count) {
            $validIdx += [int]$item - 1
        } else {
            Write-Host "Invalid selection: $item" -ForegroundColor Yellow
        }
    }

    if ($validIdx.Count -eq 0) {
        Write-Host "Invalid selection." -ForegroundColor Red
        continue
    }

    Write-Host "`nSelected scripts:" -ForegroundColor Cyan
    foreach ($idx in $validIdx) {
        Write-Host "$($idx+1). $($winScripts[$idx].name)"
        Write-Host "   URL: $($winScripts[$idx].url)"
    }

    $run = Read-Host "Run the selected script(s) now? (y/n)"
    if ($run -eq "y") {
        foreach ($idx in $validIdx) {
            $s = $winScripts[$idx]
            Write-Host "Running $($s.name)..."
            (Invoke-WebRequest -Uri $s.url -UseBasicParsing).Content | Invoke-Expression
        }
    }
    Write-Host ""
}
Remove-Item $tmpJson -Force
