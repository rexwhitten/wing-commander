$ErrorActionPreference = "Stop"

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

$user = "$($env:USERDOMAIN)\$($env:UserName)";
$docker_group = "docker-users";

# Add current user to the docker group
$members = Get-LocalGroupMember -Name $docker_group | Select-Object -ExpandProperty Name 
if($members -contains $user){
    Write-Host "$($user) exists in the group $($docker_group)"
} Else {
    # Add Current Userto docker groups
    Write-Host "$($user) doesnt exist in the group $($docker_group)"
    Add-LocalGroupMember -Group $docker_group -Member  $user
}


# Setup Docker Powershell 
# - update the registered repository 
# - install the docker powershell module
if(Get-PSRepository -Name DockerPS-Dev) {
   Write-Host "Docker PS Dev repository registered."
} Else {
    Write-Host "Docker PS Dev repository is not registered."
    Register-PSRepository -Name DockerPS-Dev -SourceLocation https://ci.appveyor.com/nuget/docker-powershell-dev
}
if (Get-Module -ListAvailable -Name Docker) {
    Write-Host "Docker module exists - updating"
    Update-Module -Name Docker
} else {
    Write-Host "Docker module does not exist - installing"
    Install-Module -Name Docker -Repository DockerPS-Dev -Scope CurrentUser
    Update-Module -Name Docker
}

# Start Docker Service 
$docker_service_running = Get-Service | Where {$_.Name -eq 'com.docker.service'} | Select-Object -ExpandProperty Status;
if($docker_service_running -eq $true) {
    Write-Host "Docker service is running"
} Else {
    Write-Host "Starting Docker service"
    Start-Service -Name "com.docker.service"
}