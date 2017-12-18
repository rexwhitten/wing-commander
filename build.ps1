# references
. "scripts/iterate.ps1"

# setp docker
# https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon

$current_directory = (Get-Item -Path ".\" -Verbose).FullName
iterateFiles($current_directory);

# setup local cluster 
& "cluster\DevClusterSetup.ps1"

# build and deploy the service fabric solutions in src 

# start all support containers 

