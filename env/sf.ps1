. ".\ps\functions.ps1"
$ErrorActionPreference = "Stop"

# variables - install
$sf_server_package_path = "\\sompofs3\groupdir\it\Installs\SF Server Package\Microsoft.Azure.ServiceFabric.WindowsServer.6.1.467.9494\*";
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
          -Recurse `
# end 

# determine state of sf cluster 
# HKLM:\SOFTWARE\Microsoft\Service Fabric'
if(Test-RegistryPath -Path "HKLM:\SOFTWARE\Microsoft\Service Fabric") {
    Write-Host "SF is installed ... cleaning"
    # execute Clean 
    Invoke-Expression "$sf_local_server\CleanFabric.ps1";
}

# Validate environment 
Invoke-Expression "$sf_local_server\TestConfiguration.ps1 -ClusterConfigFilePath $sf_clu_config_path"

# Create the Cluster 
Invoke-Expression "$sf_local_server\CreateServiceFabricCluster.ps1 -ClusterConfigFilePath $sf_clu_config_path -AcceptEULA"