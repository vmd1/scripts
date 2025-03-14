# Script created by Vivaan Modi

$uninstallKeys = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 
    'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)

function Get-InstalledApp($appName) {
    foreach ($key in $uninstallKeys) {
        if (Test-Path $key) {
            Get-ChildItem -Path $key | ForEach-Object {
                $displayName = $_.GetValue('DisplayName')
                if ($displayName -and $displayName -match [regex]::Escape($appName)) {
                    return $_.PSPath
                }
            }
        }
    }
    return $null
}

function Uninstall-App($appName) {
    $appRegPath = Get-InstalledApp $appName
    if ($appRegPath) {
        Write-Output "Found registry path: $appRegPath"
        $appProperties = Get-ItemProperty -Path $appRegPath -ErrorAction SilentlyContinue
        if ($appProperties -and $appProperties.UninstallString) {
            $uninstallString = $appProperties.UninstallString
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
            if (Test-Path $exePath) {
                Start-Process -FilePath $exePath -ArgumentList $arguments -NoNewWindow -Wait
            } else {
                Write-Output "Uninstaller not found. Deleting registry entry."
                Remove-Item -Path $appRegPath -Recurse -Force
            }
        } else {
            Write-Output "No uninstall string found for: $appName"
        }
    } else {
        Write-Output "$appName not found in registry."
    }
}

function Uninstall-Firefox-Appx {
    $firefoxAppx = Get-AppxPackage | Where-Object { $_.Name -match "Mozilla.Firefox" }
    if ($firefoxAppx) {
        Write-Output "Uninstalling Firefox AppX package: $($firefoxAppx.Name)"
        Remove-AppxPackage -Package $firefoxAppx.PackageFullName
    }
}

function Delete-Browser-Folders {
    $folders = @(
        "$env:LOCALAPPDATA\Mozilla",
        "$env:APPDATA\Mozilla",
        "$env:ProgramFiles\Opera",
        "$env:ProgramFiles(x86)\Opera",
        "$env:LOCALAPPDATA\Opera",
        "$env:APPDATA\Opera",
        "$env:LOCALAPPDATA\Opera GX",
        "$env:APPDATA\Opera GX"
    )
    
    foreach ($folder in $folders) {
        if (Test-Path $folder) {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output "Deleted: $folder"
        }
    }
}

# Execute functions
Uninstall-App "Firefox"
Uninstall-Firefox-Appx
Uninstall-App "Opera"
Uninstall-App "Opera GX"
Delete-Browser-Folders
