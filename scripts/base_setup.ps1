# While `mkdir -force` works fine when dealing with regular folders, it behaves
# strange when using it at registry level. If the target registry key is
# already present, all values within that key are purged.
Function force_mkdir($path) {
    if (!(Test-Path $path)) {
        #Write-Host "-- Creating full path to: " $path -ForegroundColor White -BackgroundColor DarkGreen
        New-Item -ItemType Directory -Force -Path $path
    }
}


Invoke-WebRequest -Uri "$env:PACKER_HTTP_ADDR/7z1900-x64.msi" -OutFile "C:\Windows\Temp\7zip.msi"

Write-Host "Disabling Screensaver"
Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name ScreenSaveActive -Value 0 -Type DWord
& powercfg -x -monitor-timeout-ac 0
& powercfg -x -monitor-timeout-dc 0


Write-Host "Enabling RDP"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"


Write-Host "Enabling Microsoft Updates"
$ServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
$ServiceManager.ClientApplicationID = "My App"
$ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")


#   Description:
# This script optimizes Windows updates by disabling automatic download and
# seeding updates to other computers.

Write-Host "Disable automatic download and installation of Windows updates"
force_mkdir 'HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\WindowsUpdate\AU'
Set-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoUpdate" 0
Set-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUOptions" 2
Set-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\WindowsUpdate\AU" "ScheduledInstallDay" 0
Set-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\WindowsUpdate\AU" "ScheduledInstallTime" 3

# done in decrapifier
<#Write-Host "Disable seeding of updates to other computers via Group Policies"
force_mkdir 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0#>

#echo "Disabling automatic driver update"
#sp "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "SearchOrderConfig" 0

<#$objSID = New-Object System.Security.Principal.SecurityIdentifier "S-1-1-0"
$EveryOne = $objSID.Translate( [System.Security.Principal.NTAccount]).Value

Write-Host "Disable 'Updates are available' message"
takeown /F "$env:WinDIR\System32\MusNotification.exe"
icacls "$env:WinDIR\System32\MusNotification.exe" /deny "$($EveryOne):(X)"
takeown /F "$env:WinDIR\System32\MusNotificationUx.exe"
icacls "$env:WinDIR\System32\MusNotificationUx.exe" /deny "$($EveryOne):(X)"#>
