# local system installation script
$ErrorActionPreference = "Stop"

# Enable Hyper-V and Containers Windows 10 Features 
Enable-WindowsOptionalFeature `
    -FeatureName "Microsoft-Hyper-V", "Containers" `
    -Online `
    -All ;

# Enable Remote Registry Service 
Set-Service -Name RemoteRegistry -ComputerName $env:COMPUTERNAME -StartupType Automatic

# install chocolatey
Write-Host "Installing chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
Write-Host "choco installed"

# Install WPI CLI
choco install webpi

# Install pip
Write-Host "Installing pip via choco"
Invoke-Expression -Command "choco install pip --force -y"