$ErrorActionPreference = "Stop"

# Download Docker package 
Write-Host "[begin]::container\install.ps1";
Write-Host "[info]::container\install.ps1 - downloading installerdocker.msi";
Invoke-WebRequest `
    -Uri 'https://download.docker.com/win/stable/InstallDocker.msi' `
    -OutFile 'C:\Temp\InstallDocker.msi' ;

# Install Docker 
Write-Host "[info]::container\install.ps1 - installing docker";
Start-Process `
    -FilePath 'C:\Windows\System32\msiexec.exe' `
    -ArgumentList '/I C:\Temp\InstallDocker.msi /quiet' `
    -Wait ;

# Switch Docker to Windows Containers 
# Need to handle both Linux and Windows Container
Write-Host "[info]::container\install.ps1 switching docker to windows containers";
Start-Process `
    -FilePath 'C:\Program Files\Docker\Docker\DockerCli.exe' `
    -ArgumentList '-SwitchDaemon' `
    -Wait ;

$user = "$($env:USERDOMAIN)\$($env:UserName)";
$docker_group = "docker-users";

# Add current user to the docker group
Write-Host "[info]::container\install.ps1 - adding current user to the docker group";
$members = Get-LocalGroupMember -Name $docker_group | Select-Object -ExpandProperty Name 
if($members -contains $user){
    Write-Host "$($user) exists in the group $($docker_group)"
    Write-Host "[info]::container\install.ps1 - $($user) exist in the group $($docker_group)";
} Else {
    # Add Current Userto docker groups
    Write-Host "[info]::container\install.ps1 - $($user) doesnt exist in the group $($docker_group)";
    Add-LocalGroupMember -Group $docker_group -Member  $user
}


# Setup Docker Powershell 
# - update the registered repository 
# - install the docker powershell module
if(Get-PSRepository -Name DockerPS-Dev) {
   Write-Host "[info]::container\install.ps1 - ps-dev repository is registered";
} Else {
    Write-Host "[info]::container\install.ps1 - ps-dev repository is not registered";
    Register-PSRepository -Name DockerPS-Dev `
                          -SourceLocation https://ci.appveyor.com/nuget/docker-powershell-dev `
                          -InstallationPolicy Trusted
}
if (Get-Module -ListAvailable -Name Docker) {
    Write-Host "[info]::container\install.ps1 - docker module exists - updating";
    Update-Module -Name Docker
} else {
    Write-Host "[info]::container\install.ps1 - docker module does not exist - installing";
    Install-Module -Name Docker `
                   -Repository DockerPS-Dev `
                   -Scope CurrentUser `
    Update-Module -Name Docker
}

# Start Docker Service 
$docker_service_running = Get-Service | Where {$_.Name -eq 'com.docker.service'} | Select-Object -ExpandProperty Status;
if($docker_service_running -eq $true) {
    Write-Host "[info]::container\install.ps1 - docker service running";
} Else {
    Write-Host "[info]::container\install.ps1 - starting docker service";
    Start-Service -Name "com.docker.service"
}
Write-Host "[begin]::container\install.ps1";