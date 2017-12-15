param
(
    [Parameter(Mandatory=$False, Position=1)]
    [switch] $Auto
)

function ExitWithCode($exitcode)
{
    if($Auto.IsPresent)
    {
        $host.SetShouldExit($exitcode)        
    }

    exit
}

trap [System.Exception]
{   
  Write-Host $_
  break
  ExitWithCode 1
}


# Import the cluster setup utility module
$sdkInstallPath = (Get-ItemProperty 'HKLM:\Software\Microsoft\Service Fabric SDK').FabricSDKScriptsPath
$modulePath = Join-Path -Path $sdkInstallPath -ChildPath "ClusterSetupUtilities.psm1"
Import-Module $modulePath

EnsureAdminPrivileges "Not running as administrator. You need to run PoweShell with administrator privileges to clean the local cluster."

CleanExistingCluster

Write-Host ""
Write-Host "Local Service Fabric Cluster removed successfully." -ForegroundColor Green
Write-Host ""
Write-Warning "Please close this PowerShell window."
Write-Host ""

<#
.SYNOPSIS 
	Removes a local Service Fabric cluster.

.DESCRIPTION
	This script removes an existing local Service Fabric cluster on the machine.

.PARAMETER Auto
    For internal use by Service Fabric tools.

.EXAMPLE
    CleanCluster.ps1
#>