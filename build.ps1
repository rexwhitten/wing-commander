# references
. "scripts/iterate.ps1"

$current_directory = (Get-Item -Path ".\" -Verbose).FullName
iterateFiles($current_directory);

# build + test all solutions in src 

# prepare all docker containers ( Service Fabric projects in src)

# configure virtual networking

# configure local service fabric cluster 

# deploy all solutions to the service fabric cluster/nodes 

# open a broweser to the main application

