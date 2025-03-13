$uninstallKeys = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 
    'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)

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

function Remove-Apps {
    $apps = Get-InstalledApps
    if ($apps.Count -eq 0) {
        Write-Output "No installed applications found."
        return
    }

    Write-Output "Installed applications:"
    $appList = $apps.Keys | Sort-Object
    for ($i = 0; $i -lt $appList.Count; $i++) {
        Write-Output "$($i + 1). $($appList[$i])"
    }

    $selection = Read-Host "Enter the number(s) of the apps to uninstall (comma-separated)"
    $indexes = $selection -split ',' | ForEach-Object { $_.Trim() -as [int] }

    foreach ($index in $indexes) {
        if ($index -gt 0 -and $index -le $appList.Count) {
            $appName = $appList[$index - 1]
            $uninstallString = (Get-ItemProperty -Path $apps[$appName]).UninstallString
            
            if ($uninstallString) {
                Write-Output "Uninstalling: $appName"

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
        } else {
            Write-Output "Invalid selection: $index"
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

    $selection = Read-Host "Enter the number(s) of the apps to delete from registry (comma-separated)"
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

function Clear-PSHistory {
    rm (Get-PSReadLineOption).HistorySavePath
    Write-Output "PowerShell history cleared."
}

function Empty-RecycleBin {
    try {
        [void] [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory('C:\$Recycle.Bin', 'Delete', 'AllowSubdirectoriesToBeCreated')
        Write-Output "Recycle bin emptied."
    } catch {
        Write-Output "Error while emptying recycle bin: $_"
    }
}

while ($true) {
    Clear-Host
    Write-Host "Select an option:"
    Write-Host "1. View all installed applications"
    Write-Host "2. Uninstall applications"
    Write-Host "3. Delete specific registry entries"
    Write-Host "4. Clear PowerShell history"
    Write-Host "5. Empty Recycle Bin"
    Write-Host "6. Exit"
    $choice = Read-Host "Enter your choice (1/2/3/4/5/6)"

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
        "2" { Remove-Apps }
        "3" { Remove-RegistryEntry }
        "4" { Clear-PSHistory }
        "5" { Empty-RecycleBin }
        "6" { break }
        default { Write-Output "Invalid choice. Try again." }
    }
}
