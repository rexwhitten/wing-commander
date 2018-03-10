. ".\ps\functions.ps1"
$ErrorActionPreference = "Stop"

# variables - install
$sf_server_package_path = "\\sompofs3\groupdir\it\Installs\SF Server Package\Microsoft.Azure.ServiceFabric.WindowsServer.6.1.467.9494\*";
$sf_server_package_tools_path = "$sf_server_package_path\Tools"
$sf_local_root = "C:\SF"
$sf_local_server = "$sf_local_root\server\"
$sf_local_FabricDataRoot = "$sf_local_root\data\"
$sf_local_FabricLogRoot = "$sf_local_root\log\"
$sf_local_diag_store = "$sf_local_root\DiagnosticsStore"

# variables - config 
$sf_clu_config_path = ".\cluster\ClusterConfig.Unsecure.DevCluster.json"

# create local SF Directories 
Reset-Directory -path .\DeploymentTraces
Reset-Directory -path $sf_local_root
Reset-Directory -path $sf_local_server
Reset-Directory -path $sf_local_FabricDataRoot
Reset-Directory -path $sf_local_FabricLogRoot
Reset-Directory -path $sf_local_diag_store

Copy-Item -Path $sf_server_package_path `
          -Destination $sf_local_server `
          -Recurse 
# end 

# install 
Invoke-Expression -Command "choco install MicrosoftAzure-ServiceFabric-CoreSDK --source webpi --confirm --force --force-dependencies"

# clean
$is_installed = Test-RegistryPath -path "HKLM:\SOFTWARE\Microsoft\Service Fabric"
if($is_installed -eq $true) {
    Invoke-Expression "$sf_local_server\CleanFabric.ps1";
}

Write-Host $sf_local_server

# Validate environment 
Invoke-Expression "$sf_local_server\TestConfiguration.ps1 -ClusterConfigFilePath $sf_clu_config_path"

# Create the Cluster 
#Invoke-Expression "$sf_local_server\CreateServiceFabricCluster.ps1 -ClusterConfigFilePath $sf_clu_config_path -AcceptEULA"