# Creates the Local Cluster
# --------------------------------------------
$ErrorActionPreference = "Stop"

# Variables
$sf_version = "6.1.467.9494";
$sf_runtime_package_path = "\\sompofs3\groupdir\it\Installs\SF Server Package\MicrosoftAzureServiceFabric.$($sf_version).cab";
$sf_local_path = "C:\sf\$($sf_version)";
$cluster_config_path = "$PSScriptRoot\ClusterConfig.Windows.DevCluster.json"

# Remove previous service fabric installation 
Write-Host "Executing clean up"
# If first time, do not cleanup, if not execute clean up
If (Get-Service FabricInstallerSvc -ErrorAction SilentlyContinue) {
    Write-Host "Service found."
    CleanFabric.ps1 
} Else {
    Write-Host "Service not found."
}

# Delete all Deployment Trace files
Write-Host "Removing previous deployment trace files"
Remove-Item -Path .\DeploymentTraces -Force -Recurse -ErrorAction Ignore

# Install Service Fabric Server Package + Runtime 
Write-Host "Installing Service Fabric Server Package"
New-ServiceFabricCluster -ClusterConfigurationFilePath $cluster_config_path `
                         -FabricRuntimePackagePath $sf_runtime_package_path 

# Test configuration 
Write-Host "Executing Service Fabric Configuration Test"
Test-ServiceFabricConfiguration -ClusterConfigurationFilePath $cluster_config_path `
                                -FabricRuntimePackagePath $sf_runtime_package_path 

# Service Fabric
Write-Host "Service Fabric Cluster is ready"