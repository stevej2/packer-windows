<#
If you want to get information regarding specific features, type

Get-WindowsOptionalFeature -Online -FeatureName *Type feature name*

In order to enable/disable any feature use the following commands.

Enable-WindowsOptionalFeature -Online -FeatureName “Type feature name” -all

Disable-WindowsOptionalFeature -Online -FeatureName “Type feature name”#>


$addfeatures = @(
# Needed to run Hyper-v VMs on Windows
"Microsoft-Hyper-V"

# Needed to run VirtualBox, Docker etc on Windows
"HyperVisorPlatform"

# Might be needed in future (from build 18917) to run Linux on Windows
# see https://docs.microsoft.com/en-us/windows/wsl/wsl2-install
#"VirtualMachinePlatform"

)
foreach ($feature in $addfeatures) {
    Write-Host "Trying to enable $feature"
    Enable-WindowsOptionalFeature -Online -norestart -FeatureName $feature -all
}

$removefeatures = @(
"WorkFolders-Client"
)
foreach ($feature in $removefeatures) {
    Write-Host "Trying to disable $feature"
    Disable-WindowsOptionalFeature -Online -norestart -FeatureName $feature
}