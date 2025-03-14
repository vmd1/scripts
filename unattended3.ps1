# Script created by Vivaan Modi

$uninstallKeys = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 
    'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)

$targetApps = @("Mozilla Firefox", "Opera")

function Get-InstalledApps {
    $apps = @{ }
    foreach ($key in $uninstallKeys) {
        if (Test-Path $key) {
            Get-ChildItem -Path $key | ForEach-Object {
                $displayName = $_.GetValue('DisplayName')
                $uninstallString = $_.GetValue('UninstallString')
                if ($displayName -and $uninstallString) {
                    $apps[$displayName] = @{ Path = $_.PSPath; Uninstall = $uninstallString }
                }
            }
        }
    }
    return $apps
}

function Uninstall-App {
    param(
        [string]$appName, 
        [string]$uninstallString, 
        [string]$regPath
    )
    
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

    if (Test-Path $exePath) {
        Write-Output "Uninstalling: $appName"
        Start-Process -FilePath $exePath -ArgumentList $arguments -NoNewWindow -Wait
    } else {
        Write-Output "$appName uninstaller not found. Removing registry entry."
        Remove-Item -Path $regPath -Recurse -Force
    }
}

function Uninstall-Firefox-AppX {
    $firefoxPackage = Get-AppxPackage | Where-Object { $_.Name -like "*Mozilla.Firefox*" }
    if ($firefoxPackage) {
        Write-Output "Removing Firefox AppX package: $($firefoxPackage.Name)"
        Remove-AppxPackage -Package $firefoxPackage.PackageFullName
    }
}

function Unattended-Uninstall {
    $installedApps = Get-InstalledApps
    foreach ($app in $targetApps) {
        if ($installedApps.ContainsKey($app)) {
            $uninstallString = $installedApps[$app].Uninstall
            $regPath = $installedApps[$app].Path
            Uninstall-App -appName $app -uninstallString $uninstallString -regPath $regPath
        }
    }
    Uninstall-Firefox-AppX
}

Unattended-Uninstall
