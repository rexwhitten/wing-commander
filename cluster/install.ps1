# script imports
. ".\ps\functions.ps1"
#script parameters
$ErrorActionPreference = "Stop"

# variables
$sf_sf_program_data_path = "C:\ProgramData\SF\";
$sf_server_package_path = "https://go.microsoft.com/fwlink/?linkid=839354";
$sf_server_package_temp_path = "C:\temp\sf";
$sf_local_root = "C:\SF"
$sf_local_server = "$sf_local_root\server\"
$sf_local_FabricDataRoot = "$sf_local_root\data\"
$sf_local_FabricLogRoot = "$sf_local_root\log\"
$sf_local_diag_store = "$sf_local_root\DiagnosticsStore"

# variables - config 
$sf_clu_config_path = ".\cluster\config\ClusterConfig.Unsecure.DevCluster.json"

Write-Host "[begin]::cluster_config"
# create local SF Directories 
Reset-Directory -path .\DeploymentTraces
Reset-Directory -path $sf_local_root
Reset-Directory -path $sf_local_server
Reset-Directory -path $sf_local_FabricDataRoot
Reset-Directory -path $sf_local_FabricLogRoot
Reset-Directory -path $sf_local_diag_store
#Reset-Directory -path $sf_sf_program_data_path
#Reset-Directory -path $sf_server_package_temp_path

# Service Fabric Runtime
#   Download($sf_server_package_path, $sf_server_package_temp_path)
#   $cab_file = Find-Latest($sf_server_package_temp_path);
#   Unpack-Cab($cab_file, $sf_local_server)
Write-Host "[info]::msg:copying: $sf_server_package_temp_path\* $sf_local_server"
Copy-Item -Path "$sf_server_package_temp_path\*" `
          -Destination $sf_local_server `
          -Recurse 
# end

# install 
#Invoke-Expression -Command "choco install MicrosoftAzure-ServiceFabric-CoreSDK --source webpi --confirm --force --force-dependencies"
#Invoke-Expression "$sf_local_server\CleanFabric.ps1";

# Validate environment 
Try {
    Invoke-Expression "$sf_local_server\TestConfiguration.ps1 -ClusterConfigFilePath $sf_clu_config_path -eq 1"
}
Catch {
    Write-Host "[info]::msg:Service Fabric - Error while running TestConfiguration.ps1";
    $t= ((Test-RegistryPath -path "HKLM:\SOFTWARE\Microsoft\Service Fabric") -eq $true);
    If ($t) {
        Write-Host "[info]::msg:Service Fabric Registry Path Exists"
        Write-Host "[info]::msg:Service Fabric - running CleanFabric.ps1"
        Invoke-Expression "$sf_local_server\CleanFabric.ps1"
    } Else {
        Write-Host "[info]::msg:Service Fabric Registry Path Does Not Exist"
    }
}

# Create the Cluster 
Invoke-Expression "$sf_local_server\CreateServiceFabricCluster.ps1 -ClusterConfigFilePath $sf_clu_config_path -AcceptEULA"
Write-Host "[end]::cluster_config"