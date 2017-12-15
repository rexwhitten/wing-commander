param
(
    [Parameter(Mandatory=$False, Position=1)]
    [string] $PathToClusterDataRoot = "",
    
    [Parameter(Mandatory=$False, Position=2)]
    [string] $PathToClusterLogRoot = "",
    
    [Parameter(Mandatory=$False, Position=3)]
    [switch] $AsSecureCluster,
    
    [Parameter(Mandatory=$False, Position=4)]
    [switch] $UseMachineName,

    [Parameter(Mandatory=$False, Position=5)]
    [switch] $CreateOneNodeCluster,

    [Parameter(Mandatory=$False, Position=6)]
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

Get-Module -ListAvailable -Refresh --quiet *>$null

# Import the cluster setup utility module
$sdkInstallPath = (Get-ItemProperty 'HKLM:\Software\Microsoft\Service Fabric SDK').FabricSDKScriptsPath
$modulePath = Join-Path -Path $sdkInstallPath -ChildPath "ClusterSetupUtilities.psm1"
Import-Module $modulePath

EnsureAdminPrivileges "Not running as administrator. You need to run PoweShell with administrator privileges to setup the local cluster."

if((IsLocalClusterSetup))
{
    if(!$Auto.IsPresent)
     {
        Write-Warning "A local Service Fabric Cluster already exists on this machine and will be removed."
        $response = Read-Host -Prompt "Do you want to continue [Y/N]?"
        if($response -ine "Y") { ExitWithCode 0 }
    }
        
    CleanExistingCluster
}

$jsonFileTemplate = SelectJsonFileTemplate -isSecure $AsSecureCluster.IsPresent -createOneNodeCluster $CreateOneNodeCluster.IsPresent
$clusterRoots = SetupDataAndLogRoot -clusterDataRoot $PathToClusterDataRoot -clusterLogRoot $PathToClusterLogRoot -jsonFileTemplate $jsonFileTemplate -isAuto $Auto.IsPresent

if($clusterRoots[0] -eq $False)
{
    ExitWithCode -exitcode 0
}

$clusterDataRoot = $clusterRoots[0]
$clusterLogRoot = $clusterRoots[1]

if ($AsSecureCluster.IsPresent) { InstallCertificates }

DeployNodeConfiguration $clusterDataRoot $clusterLogRoot $AsSecureCluster.IsPresent $UseMachineName.IsPresent -createOneNodeCluster $CreateOneNodeCluster.IsPresent

StartLocalCluster

$connParams = GetConnectionParameters -isSecure $AsSecureCluster.IsPresent -useMachineName $UseMachineName.IsPresent

TryConnectToCluster -connParams $connParams -waitTime 240
CheckNamingServiceReady -connParams $connParams -waitTime 120

$outputString = @"

Local Service Fabric Cluster created successfully.

================================================= 
## To connect using Powershell, open an a new powershell window and connect using 'Connect-ServiceFabricCluster' command (without any arguments)."

## To connect using Service Fabric Explorer, run ServiceFabricExplorer and connect using 'Local/OneBox Cluster'."

## To manage using Service Fabric Local Cluster Manager (system tray app), run ServiceFabricLocalClusterManager.exe"
=================================================
"@

Write-Host $outputString -ForegroundColor Green

##
## TODO: Possibily launch the web version of Service Fabric Explorer i.e. SFX 
##

<#
.SYNOPSIS 
	Sets up a local Service Fabric cluster.

.DESCRIPTION
	This script sets up a local Service Fabric cluster for development of Service Fabric based services using Visual Studio.

.PARAMETER PathToClusterDataRoot
	Path to the directory where local cluster will be setup. E.g. C:\MyDevCluster\Data

.PARAMETER PathToClusterLogRoot
	Path to the directory where traces and logs from local cluster will be stored. E.g. C:\MyDevCluster\Log

.PARAMETER AsSecureCluster
	Indicates if a secure local cluster needs to be setup.

.PARAMETER UseMachineName
    Indicates if  DNS name of the machine should be used in cluster manifest.

.PARAMETER CreateOneNodeCluster
    Indicates if a local cluster with one node should be setup using the template cluster mannifest file.

.PARAMETER Auto
    If presents does not promp for confirmation before deleting any folder or removing an existing cluster.

.EXAMPLE
    DevClusterSetup.ps1

.EXAMPLE
	DevClusterSetup.ps1 -PathToClusterDataRoot "C:\MyDevCluster\Data" -PathToClusterLogRoot "C:\MyDevCluster\Log"
#>