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

$winScripts = $json | Where-Object { $_.oses -contains "windows" }
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
    $choice = Read-Host "Select a script to view details or run (number)"
    if ($choice -eq "q") { break }
    if ($choice -match "^[0-9]+$" -and $choice -ge 1 -and $choice -le $winScripts.Count) {
        $idx = $choice - 1
        $script = $winScripts[$idx]
        Write-Host "`nName: $($script.name)"
        Write-Host "URL: $($script.url)"
        $run = Read-Host "Run this script now? (y/n)"
        if ($run -eq "y") {
            Write-Host "Running $($script.name)..."
            Invoke-WebRequest -Uri $script.url -UseBasicParsing | Invoke-Expression
        }
    } else {
        Write-Host "Invalid selection." -ForegroundColor Red
    }
    Write-Host ""
}
Remove-Item $tmpJson -Force
