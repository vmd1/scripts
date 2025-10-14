# fetch the CSV
$csvUrl = "https://sc.vmd1.dev/500plus/data/scripts.csv"
try {
    $csv = Invoke-WebRequest -Uri $csvUrl -UseBasicParsing | ConvertFrom-Csv
} catch {
    Write-Host "❌ failed to fetch or parse the CSV from $csvUrl" -ForegroundColor Red
    exit
}

if (-not $csv) {
    Write-Host "❌ no data found in CSV" -ForegroundColor Red
    exit
}

# display a numbered, scrollable table
$index = 1
$display = $csv | ForEach-Object {
    [PSCustomObject]@{
        "#"          = $index++
        SCRIPT       = $_.SCRIPT
        CATEGORY     = $_.CATEGORY
        DESCRIPTION  = $_.DESCRIPTION
    }
}

$display | Out-Host -Paging

# ask user which script to run
$selection = Read-Host "enter the script number you want to run"
if ($selection -match '^\d+$' -and $selection -gt 0 -and $selection -le $csv.Count) {
    $selectedScript = $csv[$selection - 1].SCRIPT
    $scriptUrl = "https://sc.vmd1.dev/500plus/scripts/$selectedScript"
    Write-Host "`n➡ running: $selectedScript" -ForegroundColor Cyan
    Write-Host "📜 source: $scriptUrl`n" -ForegroundColor DarkGray
    
    # download and execute
    try {
        Invoke-Expression (Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing).Content
    } catch {
        Write-Host "❌ failed to run $selectedScript" -ForegroundColor Red
    }
} else {
    Write-Host "⚠ invalid selection" -ForegroundColor Yellow
}
