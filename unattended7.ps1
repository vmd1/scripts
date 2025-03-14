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

function Remove-App-Paths {
    $pathsToRemove = @(
        "$env:LOCALAPPDATA\Mozilla\Firefox",
        "$env:LOCALAPPDATA\Opera Software",
        "$env:APPDATA\Opera Software",
        "$env:LOCALAPPDATA\Programs\Opera"
    )
    
    foreach ($path in $pathsToRemove) {
        if (Test-Path $path) {
            Write-Output "Removing path: $path"
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Unattended-Uninstall {
    $installedApps = Get-InstalledApps
    foreach ($app in $targetApps) {
        $matchingApp = $installedApps.Keys | Where-Object { $_ -like "*$app*" }
        if ($matchingApp) {
            $uninstallString = $installedApps[$matchingApp].Uninstall
            $regPath = $installedApps[$matchingApp].Path
            Uninstall-App -appName $matchingApp -uninstallString $uninstallString -regPath $regPath
        }
    }
    Uninstall-Firefox-AppX
    Remove-App-Paths
}

Write-Host "Script created by Vivaan Modi" -ForegroundColor Cyan
Write-Host "Disclaimer: This program comes with ABSOLUTELY NO WARRANTY, to the extent permitted by applicable law." -ForegroundColor Cyan
Write-Host "Beginning Unattended Uninstall" -ForegroundColor Green
Unattended-Uninstall
