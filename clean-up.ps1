# Script created by Vivaan Modi

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
        Read-Host "Press Enter to return to the menu"
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
    Read-Host "Press Enter to return to the menu"
}

function Remove-RegistryEntry {
    $apps = Get-InstalledApps
    if ($apps.Count -eq 0) {
        Write-Output "No installed applications found."
        Read-Host "Press Enter to return to the menu"
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
    Read-Host "Press Enter to return to the menu"
}

function Clear-PSHistory {
    rm (Get-PSReadLineOption).HistorySavePath
    Write-Output "PowerShell history cleared."
    Read-Host "Press Enter to return to the menu"
}

function Empty-RecycleBin {
    try {
        [void] [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory('C:\$Recycle.Bin', 'Delete', 'AllowSubdirectoriesToBeCreated')
        Write-Output "Recycle bin emptied."
    } catch {
        Write-Output "Error while emptying recycle bin: $_"
    }
    Read-Host "Press Enter to return to the menu"
}

function Remove-RawRegistryEntries {
    $entries = @{}
    $index = 1

    foreach ($key in $uninstallKeys) {
        if (Test-Path $key) {
            Get-ChildItem -Path $key | ForEach-Object {
                $entries[$index] = $_.PSPath
                Write-Output "$index. $($_.PSPath)"
                $index++
            }
        }
    }

    if ($entries.Count -eq 0) {
        Write-Output "No uninstall registry entries found."
        Read-Host "Press Enter to return to the menu"
        return
    }

    $selection = Read-Host "Enter the number(s) of the registry entries to delete (comma-separated)"
    $indexes = $selection -split ',' | ForEach-Object { $_.Trim() -as [int] }

    foreach ($index in $indexes) {
        if ($entries.ContainsKey($index)) {
            $regPath = $entries[$index]
            Remove-Item -Path $regPath -Recurse -Force
            Write-Output "Deleted registry entry: $regPath"
        } else {
            Write-Output "Invalid selection: $index"
        }
    }
    Read-Host "Press Enter to return to the menu"
}

function Get-AppxPackages {
    Write-Output "Listing all installed MSIX/AppX packages:"
    Get-AppxPackage | Select-Object Name, PackageFullName | ForEach-Object {
        Write-Output "Name: $($_.Name)"
        Write-Output "Package: $($_.PackageFullName)"
        Write-Output "--------------------------------------"
    }
    Read-Host "Press Enter to return to the menu"
}

function Remove-AppxByName {
    $Name = Read-Host "Enter the package name to remove"

    $packages = Get-AppxPackage | Where-Object { $_.Name -like "*$Name*" }

    if ($packages.Count -eq 0) {
        Write-Output "No matching packages found."
        return
    }

    Write-Output "Matching packages:"
    for ($i = 0; $i -lt $packages.Count; $i++) {
        Write-Output "$($i + 1). $($packages[$i].Name)"
    }

    $selection = Read-Host "Enter the number(s) of the packages to remove (comma-separated)"
    $indexes = $selection -split ',' | ForEach-Object { $_.Trim() -as [int] }

    foreach ($index in $indexes) {
        if ($index -gt 0 -and $index -le $packages.Count) {
            $package = $packages[$index - 1]
            Write-Output "Removing: $($package.Name)"
            Remove-AppxPackage -Package $package.PackageFullName
            Read-Host "Press Enter to return to the menu"
        } else {
            Write-Output "Invalid selection: $index"
            Read-Host "Press Enter to return to the menu"
        }
    }
}

function Set-RegistryUser {
    param (
        [string]$username
    )
    
    $sid = (Get-WmiObject Win32_UserAccount | Where-Object { $_.Name -eq $username }).SID
    
    if (-not $sid) {
        Write-Output "User not found. Ensure the username is correct."
        Read-Host "Press Enter to return to the menu"
        return
    }
    
    $uninstallKeys = @(
        "HKU:\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKU:\$sid\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    
    Write-Output "Registry locations updated for user: $username ($sid)"
    Read-Host "Press Enter to return to the menu"
}

while ($true) {
    Clear-Host
    Write-Host "Script created by Vivaan Modi" -ForegroundColor Cyan
    Write-Host "Disclaimer: This program comes with ABSOLUTELY NO WARRANTY, to the extent permitted by applicable law." -ForegroundColor Cyan

    Write-Host "Select an option:"
    Write-Host "1. View all installed applications"
    Write-Host "2. Uninstall applications"
    Write-Host "3. Delete specific registry entries"
    Write-Host "4. Clear PowerShell history"
    Write-Host "5. Empty Recycle Bin"
    Write-Host "6. View all MSIX/AppX Packages"
    Write-Host "7. Remove an AppX Package"
    Write-Host "8. Exit"
    $choice = Read-Host "Enter your choice (1/2/3/4/5/6/7/8)"

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
        "6" { Get-AppxPackages }
        "7" { Remove-AppxByName }
        "8" { exit }
        "71" {
            $username = Read-Host "Enter the username of the target user"
            Set-RegistryUser -username $username
        }
        "72" { Remove-RawRegistryEntries }
        default { Write-Output "Invalid choice. Try again." }
    }
}
