# Container Build Script 
# This script will create acontainer using parameterized logic
param (
    [string]$container_name = "syscore1",
    [string]$script = ".\env\types\nano\nano.ps1",
    [string]$machine_script = ".\env\types\nano.ps1", 
    [string]$image = "microsoft/nanoserver",
    [string]$machine_name = "NanoServer"
    #[Parameter(Mandatory=$true)][string]$username,
    #[string]$password = $( Read-Host "Input password, please" )
 )

# modules 
Import-Module Docker

# Stop the container if its already running
# image 
# ex: docker stop clusql1
Invoke-Expression -Command "docker stop $($container_name)"

# remove the container
# image 
# ex: docker stop clusql1
Invoke-Expression -Command "docker rm $($container_name)"

# Pull the microsoft/* Docker 
# image 
# ex: docker pull microsoft/nanoserver
Invoke-Expression -Command "docker pull $($image)"

# Create a new container name sysnode1 
# using Docker Create command 
# ex: docker create -t --name $container_name -h NanoServer -i microsoft/nanoserver
# ex: microsoft/windowsservercore
Invoke-Expression -Command "docker create -t --name $($container_name) -h $($machine_name) -i $($image)"

# copy server setup script
# using Docker Copy command 
#Invoke-Expression -Command "docker cp -a $($machine_script) $($container_name):machine_setup.ps1"

# copy server type setup script
# using Docker Copy command 
#$Invoke-Expression -Command "docker cp -a $($script) $($container_name):server_setup.ps1"

# Start the container 
# interactively 
# Invoke-Expression -Command "docker start -i $($container_name)"
Invoke-Expression -Command "docker start $($container_name)"

# Run the server setup script
# Invoke-Expression -Command "docker exec -it $($container_name) powershell .\setup.ps1"
#Invoke-Expression -Command "docker exec -it $($container_name) powershell .\machine_setup.ps1"
# Run the server type setup script
#Invoke-Expression -Command "docker exec -it $($container_name) powershell .\server_setup.ps1"