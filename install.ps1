# Setup - local environment on a given machine
# - installs docker, hyper-v

# Enable Hyper-V and Containers Windows 10 Features 
Enable-WindowsOptionalFeature `
    -FeatureName "Microsoft-Hyper-V", "Containers" `
    -Online `
    -All ;

# Download Docker package 
Invoke-WebRequest `
    -Uri 'https://download.docker.com/win/stable/InstallDocker.msi' `
    -OutFile 'C:\Temp\InstallDocker.msi' ;

# Install Docker 
Start-Process `
    -FilePath 'C:\Windows\System32\msiexec.exe' `
    -ArgumentList '/I C:\Temp\InstallDocker.msi /quiet' `
    -Wait ;

# Switch Docker to Windows Containers 
Start-Process `
    -FilePath 'C:\Program Files\Docker\Docker\DockerCli.exe' `
    -ArgumentList '-SwitchDaemon' `
    -Wait ;