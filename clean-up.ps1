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
                if ($arguments) {
                    Start-Process -FilePath $exePath -ArgumentList $arguments -NoNewWindow -Wait
                } else {
                    Start-Process -FilePath $exePath -NoNewWindow -Wait
                }
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

function Exit-Script {
    rm (Get-PSReadLineOption).HistorySavePath
    exit
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

function View-AppLockerPolicies {
    Write-Output "Fetching AppLocker policies from configuration files..."
    
    $appLockerPath = "C:\Windows\System32\AppLocker\*"
    $files = Get-ChildItem -Path $appLockerPath -Recurse -File

    if ($files.Count -eq 0) {
        Write-Output "No AppLocker policy files found."
    } else {
        foreach ($file in $files) {
            Write-Output "`n--- File: $($file.FullName) ---"
            try {
                Get-Content -Path $file.FullName
            } catch {
                Write-Output "Could not read file: $($file.FullName)"
            }
        }
    }

    Read-Host "Press Enter to return to the menu"
}

function Enable-Proxy {
    $subChoice = ""
    while ($subChoice -ne "3") {
        Clear-Host
        Write-Host "Proxy Configuration" -ForegroundColor Cyan
        Write-Host "1. Enable Proxy"
        Write-Host "2. Set Proxy Address"
        Write-Host "3. Go Back"
        $subChoice = Read-Host "Enter your choice (1/2/3)"

        switch ($subChoice) {
            "1" {
                $proxyEnabled = Read-Host "Do you want to enable the proxy? (Y/N)"
                if ($proxyEnabled -eq "Y") {
                    $proxyAddress = Read-Host "Enter the proxy address (e.g., http://proxyserver:8080)"
                    $proxyEnabled = 1
                } else {
                    $proxyAddress = ""
                    $proxyEnabled = 0
                }

                # Set the proxy settings in the registry
                $proxyRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
                Set-ItemProperty -Path $proxyRegPath -Name ProxyEnable -Value $proxyEnabled
                Set-ItemProperty -Path $proxyRegPath -Name ProxyServer -Value $proxyAddress

                if ($proxyEnabled -eq 1) {
                    Write-Output "Proxy has been enabled with address: $proxyAddress"
                } else {
                    Write-Output "Proxy has been disabled."
                }
            }
            "2" {
                $proxyAddress = Read-Host "Enter the new proxy address (e.g., http://proxyserver:8080)"
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value $proxyAddress
                Write-Output "Proxy address has been set to $proxyAddress"
            }
            "3" {
                Write-Output "Returning to main menu..."
            }
            default {
                Write-Output "Invalid choice. Try again."
            }
        }
        Read-Host "Press Enter to continue"
    }
}

# Function to check if ndns is being used
function Check-NDNS {
    $ndnsHost = "ndns.infra.mdi"
    try {
        $pingResult = Test-Connection -ComputerName $ndnsHost -Count 1 -Quiet
        if ($pingResult) {
            Write-Output "ndns.infra.mdi is reachable, ndns is being used."
        } else {
            Write-Output "ndns.infra.mdi is not reachable, ndns is not being used."
        }
    } catch {
        Write-Output "Error pinging ndns.infra.mdi: $_"
    }
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
    Write-Host "4. Empty Recycle Bin"
    Write-Host "5. View all MSIX/AppX Packages"
    Write-Host "6. Remove an AppX Package"
    Write-Host "7. Exit"
    Write-Host "8. View AppLocker Policies"
    Write-Host "9. Proxy Configuration"
    Write-Host "10. Check if ndns is being used"
    $choice = Read-Host -Prompt (Write-Host "Enter your choice (1/2/3/4/5/6/7/8/9/10)" -ForegroundColor Green)

    switch ($choice) {
        "1" {
            Write-Output "Listing all installed applications and their uninstallers:"
            foreach ($key in $uninstallKeys) {
                if (Test-Path $key) {
                    Get-ChildItem -Path $key | ForEach-Object {
                        $displayName = $_.GetValue('DisplayName')
                        $uninstallString = $_.GetValue('UninstallString')
                        Write-Output "Name: $displayName"
                        Write-Output "Uninstall Command: $uninstallString"
                    }
                }
            }
        }
        "2" {
            Remove-Apps
        }
        "3" {
            Remove-RegistryEntry
        }
        "4" {
            Empty-RecycleBin
        }
        "5" {
            Get-AppxPackages
        }
        "6" {
            Remove-AppxByName
        }
        "7" {
            Exit-Script
        }
        "8" {
            View-AppLockerPolicies
        }
        "9" {
            Enable-Proxy
        }
        "10" {
            Check-NDNS
        }
        default {
            Write-Output "Invalid choice. Please select a valid option."
        }
    }
}
