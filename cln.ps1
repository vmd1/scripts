$uninstallKeys = @('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'); 
$browsers = @('Opera', 'Firefox', 'Brave', 'DuckDuckGo'); 
foreach ($key in $uninstallKeys) { 
    if (Test-Path $key) { 
        Get-ChildItem -Path $key | ForEach-Object { 
            $displayName = $_.GetValue('DisplayName'); 
            $uninstallString = $_.GetValue('UninstallString'); 
            if ($displayName -and ($browsers | Where-Object { $displayName -like "*$_*" }) -and $uninstallString) { 
                Write-Output "$displayName found. Uninstaller path: $uninstallString"; 
                # Remove surrounding quotes if present and ensure proper path handling
                $uninstallString = $uninstallString.Trim('"') 
                Start-Process -FilePath $uninstallString -Wait
            } 
        } 
    } 
}
