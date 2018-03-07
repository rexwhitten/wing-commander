# Enable Hyper-V and Containers Windows 10 Features 
Enable-WindowsOptionalFeature `
    -FeatureName "Microsoft-Hyper-V", "Containers" `
    -Online `
    -All ;


# Enable Remote Registry Service 
Set-Service -Name RemoteRegistry -ComputerName $env:COMPUTERNAME -StartupType Automatic