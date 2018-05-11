#
# Service Fabric Runtime install and Cluster Setup
# https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-cluster-creation-for-windows-server
#

#   script imports
. ".\ps\functions.ps1"
#   script parameters
$ErrorActionPreference = "Stop"

#   variables
$sf_program_data_path = "C:\ProgramData\SF\"; # this is the default path in configuration
$sf_runtime_zip_file = ".\cluster\zip\Microsoft.Azure.ServiceFabric.WindowsServer.6.1.480.9494.zip"
$sf_local_root = "C:\\mx\\SF"
$sf_local_server = "$sf_local_root\\server"
$sf_local_FabricDataRoot = "$sf_local_root\\data\\"
$sf_local_FabricLogRoot = "$sf_local_root\\log\\"
$sf_local_diag_store = "$sf_local_root\\DiagnosticsStore"

# variables - config 
$sf_clu_config_path = ".\cluster\config\ClusterConfig.Unsecure.DevCluster.json"
$backup_sf_clu_config_path = ".\cluster\config\Backup.ClusterConfig.Unsecure.DevCluster.json"

Write-Host "[begin]::cluster_config"

# 
# Imports
#
Import-Module ServiceFabric 

Write-Host "Creating Cluster Configuration"
Copy-Item -Path $backup_sf_clu_config_path -Destination $sf_clu_config_path
(Get-Content $sf_clu_config_path).replace('C:\\ProgramData\\SF', $sf_local_root) | Set-Content $sf_clu_config_path
(Get-Content $sf_clu_config_path).replace('C:\\ProgramData\\SF\\Log', $sf_local_FabricLogRoot) | Set-Content $sf_clu_config_path
(Get-Content $sf_clu_config_path).replace('C:\\ProgramData\\SF\\DiagnosticsStore', $sf_local_diag_store) | Set-Content $sf_clu_config_path

Try {
    Write-Host "Executing Clean Fabric"
    Invoke-Expression "$sf_local_server\CleanFabric.ps1"
} 
Catch {
    Write-Host $Error
    Write-Host "Error running CleanFabric.ps1";
    Write-Host "This is most likely due to a bad state of the SF runtime install, where some parts are deleted, and some arent."
}

Try {
    
    Write-Host "Executing Remove-ServiceFabricCluster"
    Remove-ServiceFabricCluster -ClusterConfigurationFilePath  $sf_clu_config_path -Force
} 
Catch {
    Write-Host $Error
    Write-Host "Error running Remove-ServiceFabricCluster";
    Write-Host "There must have been an error during the last uninstall, proceeding with install..."
}


#
# Reset local SF Directories 
#
Reset-Directory -path .\DeploymentTraces
Reset-Directory -path $sf_local_root
Reset-Directory -path $sf_local_server
Reset-Directory -path $sf_local_FabricDataRoot
Reset-Directory -path $sf_local_FabricLogRoot
Reset-Directory -path $sf_local_diag_store


#
# Unpack runtime 
#
Expand-Archive -Path $sf_runtime_zip_file -DestinationPath $sf_local_server

#
# Start the Cluster
#
Try {
    Invoke-Expression "$sf_local_server\CreateServiceFabricCluster.ps1 -ClusterConfigFilePath $sf_clu_config_path -AcceptEULA" `

} 
Catch {
    Write-Host "Error during CreateServiceFabricCluster.ps1"
}

# 
# Test the configuration 
#
#Invoke-Expression "$sf_local_server\TestConfiguration.ps1 -ClusterConfigFilePath $sf_clu_config_path -eq 1"

Write-Host "[end]::cluster_config"