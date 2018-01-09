# Build a windows container 
param (
    [string]$server = "syscore1",
    [string]$script = ".\env\types\nano\nano.ps1",
    [string]$image = "microsoft/nanoserver",
    [string]$type_name = "NanoServer"
    #[Parameter(Mandatory=$true)][string]$username,
    #[string]$password = $( Read-Host "Input password, please" )
 )

# Pull the microsoft/* Docker 
# image 
# ex: docker pull microsoft/nanoserver
Invoke-Expression -Command "docker pull $($image)"

# Create a new container name sysnode1 
# using Docker Create command 
# ex: docker create -t --name $server -h NanoServer -i microsoft/nanoserver
# ex: microsoft/windowsservercore
Invoke-Expression -Command "docker create -t --name $($server) -h $($type_name) -i $($image)"

# List all available containers using Docker 
# Container List command 
docker container ls -a

# Copy the setup PowerShell script into 
# NanoServer using Docker Copy command 
Invoke-Expression -Command "docker cp -a $($script) $($server)"

# Start the container 
# interactively 
# Invoke-Expression -Command "docker start -i $($server)"
Invoke-Expression -Command "docker start $($server)"

# Run the setup script
Invoke-Expression -Command "docker exec -it $($server) powershell $($script)"