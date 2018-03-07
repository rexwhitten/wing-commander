$ErrorActionPreference = "Stop"

# install chocolatey
Write-Host "Installing chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
Write-Host "choco installed"

# Install WPI CLI
choco install webpi

# Install pip
Write-Host "Installing pip via choco"
Invoke-Expression -Command "choco install pip --force -y"