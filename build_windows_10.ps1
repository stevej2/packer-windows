
Write-Host "Building windows_10 using Hyper-v builder"
Measure-Command { packer build --only=hyperv-iso windows_10.json }