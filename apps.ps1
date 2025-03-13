$uninstallKeys = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 
    'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)
$browsers = @('Opera', 'Firefox', 'Brave', 'DuckDuckGo')

function Get-InstalledApps {
    $apps = @{}
    foreach ($key in $uninstallKeys) {
        if (Test-Path $key) {
            Get-ChildItem -Path $key | ForEach-Object {
                $displayName = $_.GetValue('DisplayName')
                if ($displayName) {
                    $apps[$displayName] = $_.PSPath
                }
            }
        }
    }
    return $apps
}

function Remove-Browsers {
    $apps = Get-InstalledApps
    foreach ($browser in $browsers) {
        $match = $apps.Keys | Where-Object { $_ -like "*$browser*" }
        foreach ($app in $match) {
            $uninstallString = (Get-ItemProperty -Path $apps[$app]).UninstallString
            if ($uninstallString) {
                Write-Output "$app found. Uninstaller path: $uninstallString"

                if ($uninstallString -match '^"(.+?)"\s*(.*)') {
                    $exePath = $matches[1]
                    $arguments = $matches[2]
                } elseif ($uninstallString -match '^(.+?)\s+(.*)') {
                    $exePath = $matches[1]
                    $arguments = $matches[2]
                } else {
                    $exePath = $uninstallString
                    $arguments = ""
                }

                Start-Process -FilePath $exePath -ArgumentList $arguments -NoNewWindow -Wait
            }
        }
    }
}

function Remove-RegistryEntry {
    $apps = Get-InstalledApps
    if ($apps.Count -eq 0) {
        Write-Output "No installed applications found."
        return
    }

    $appList = $apps.Keys | Sort-Object
    for ($i = 0; $i -lt $appList.Count; $i++) {
        Write-Output "$($i + 1). $($appList[$i])"
    }

    $selection = Read-Host "Enter the number(s) of the apps to delete (comma-separated)"
    $indexes = $selection -split ',' | ForEach-Object { $_.Trim() -as [int] }

    foreach ($index in $indexes) {
        if ($index -gt 0 -and $index -le $appList.Count) {
            $appName = $appList[$index - 1]
            $regPath = $apps[$appName]
            Remove-Item -Path $regPath -Recurse -Force
            Write-Output "Deleted: $appName ($regPath)"
        } else {
            Write-Output "Invalid selection: $index"
        }
    }
}

while ($true) {
    Clear-Host
    Write-Host "Select an option:"
    Write-Host "1. View all installed applications"
    Write-Host "2. Remove installed browsers"
    Write-Host "3. Delete specific registry entries"
    Write-Host "4. Exit"
    $choice = Read-Host "Enter your choice (1/2/3/4)"

    switch ($choice) {
        "1" {
            Write-Output "Listing all installed applications and their uninstallers:"
            foreach ($key in $uninstallKeys) {
                if (Test-Path $key) {
                    Get-ChildItem -Path $key | ForEach-Object {
                        $displayName = $_.GetValue('DisplayName')
                        $uninstallString = $_.GetValue('UninstallString')
                        if ($displayName) {
                            Write-Output "$displayName - Uninstaller path: $uninstallString"
                        }
                    }
                }
            }
            Read-Host "Press Enter to return to the menu"
        }
        "2" { Remove-Browsers }
        "3" { Remove-RegistryEntry }
        "4" { break }
        default { Write-Output "Invalid choice. Try again." }
    }
}

# Clear PowerShell command history
rm (Get-PSReadLineOption).HistorySavePath
