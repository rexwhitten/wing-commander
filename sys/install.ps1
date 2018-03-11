# local system installation script
$ErrorActionPreference = "Stop"

Write-Host "[begin]::system\install.ps1"

# Enable Hyper-V and Containers Windows 10 Features 
Write-Host "[info]::system\install.ps1 Enabling Windows Features - HyperV and Containers";
Enable-WindowsOptionalFeature `
    -FeatureName "Microsoft-Hyper-V", "Containers" `
    -Online `
    -All ;

# Enable Remote Registry Service 
Write-Host "[info]::system\install.ps1 set remote registry service"
Set-Service -Name RemoteRegistry -ComputerName $env:COMPUTERNAME -StartupType Automatic

# install chocolatey
Write-Host "[begin]::system\install.ps1 - installing choco"
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
Write-Host "[end]::system\install.ps1 - installing choco"

# Install pip
#Write-Host "[info]::choco install pip"
#Invoke-Expression -Command "choco install pip --force -y"
#Write-Host "[end]::system\install.ps1"