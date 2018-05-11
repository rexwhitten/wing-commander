param (
    [Parameter(Mandatory=$true)]
    [string] $ClusterConfigFilePath,

    [Parameter(Mandatory=$false)]
    [switch] $AcceptEULA,

    [Parameter(Mandatory=$false)]
    [switch] $Force,

    [Parameter(Mandatory=$false)]
    [switch] $NoCleanupOnFailure,

    [Parameter(Mandatory=$false)]
    [string] $FabricRuntimePackagePath,

    [Parameter(Mandatory=$false)]
    [switch] $GenerateX509Cert,

    [Parameter(Mandatory=$false)]
    [string] $GeneratedX509CertClusterConfigPath = $null,

    [Parameter(Mandatory=$false)]
    [int] $MaxPercentFailedNodes,

    [Parameter(Mandatory=$false)]
    [int] $TimeoutInSeconds
)

$Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
$IsAdmin = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if(!$IsAdmin)
{
    Write-host "Please run the script with administrative privileges." -ForegroundColor "Red"
    exit 1
}

if(!$AcceptEULA.IsPresent)
{
    $EulaAccepted = Read-Host 'Do you accept the license terms for using Microsoft Azure Service Fabric located in the root of your package download? If you do not accept the license terms you may not use the software.
[Y] Yes  [N] No  [?] Help (default is "N")'
    if($EulaAccepted -ne "y" -and $EulaAccepted -ne "Y")
    {
        Write-host "You need to accept the license terms for using Microsoft Azure Service Fabric located in the root of your package download before you can use the software." -ForegroundColor "Red"
        exit 1
    }
}   

$ThisScriptPath = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
$DeployerBinPath = Join-Path $ThisScriptPath -ChildPath "DeploymentComponents"
if(!(Test-Path $DeployerBinPath))
{
    $DCAutoExtractorPath = Join-Path $ThisScriptPath "DeploymentComponentsAutoextractor.exe"
    if(!(Test-Path $DCAutoExtractorPath)) 
    {
        Write-Host "Standalone package DeploymentComponents and DeploymentComponentsAutoextractor.exe are not present local to the script location."
        exit 1
    }

    #Extract DeploymentComponents
    $DCExtractArguments = "/E /Y /L `"$ThisScriptPath`""
    $DCExtractOutput = cmd.exe /c "$DCAutoExtractorPath $DCExtractArguments && exit 0 || exit 1"
    if($LASTEXITCODE -eq 1)
    {
        Write-Host "Extracting DeploymentComponents Cab ran into an issue."
        Write-Host $DCExtractOutput
        exit 1
    }
    else
    {
        Write-Host "DeploymentComponents extracted."
    }
}

$SystemFabricModulePath = Join-Path $DeployerBinPath -ChildPath "System.Fabric.dll"
if(!(Test-Path $SystemFabricModulePath)) 
{
    Write-Host "Run the script local to the Standalone package directory."
    exit 1
}

$MicrosoftServiceFabricCabFileAbsolutePath = $null
if($FabricRuntimePackagePath)
{
    $MicrosoftServiceFabricCabFileAbsolutePath = Resolve-Path $FabricRuntimePackagePath
    if(!(Test-Path $MicrosoftServiceFabricCabFileAbsolutePath)) 
    {
        Write-Host "Microsoft Service Fabric Runtime package not found in the specified directory : $FabricRuntimePackagePath"
        exit 1
    }
}
else
{
    $RuntimeBinPath = Join-Path $ThisScriptPath -ChildPath "DeploymentRuntimePackages"
    if(!(Test-Path $RuntimeBinPath)) 
    {
        Write-Host "No directory exists for Runtime packages. Creating a new directory."
        md $RuntimeBinPath | Out-Null
        Write-Host "Done creating $RuntimeBinPath"
    }
}

$ClusterConfigFilePath = Resolve-Path $ClusterConfigFilePath
$ServiceFabricPowershellModulePath = Join-Path $DeployerBinPath -ChildPath "ServiceFabric.psd1"
$CertUtilityModulePath = Join-Path -Path $ThisScriptPath -ChildPath "CertInstallUtilities.psm1"
$CertSetupScript = Join-Path $ThisScriptPath -ChildPath "CertSetup.ps1"

# Create Self-Signed Cert if necessary
if ($GenerateX509Cert.IsPresent)
{
    Import-Module $CertUtilityModulePath
    if (IsSecurityX509 -ClusterConfigFilePath $ClusterConfigFilePath)
    {
        Write-Warning "GenerateX509Cert is enabled and ClusterCredentialType is X509. `
         The certificateinformation section configured on the $ClusterConfigFilePath will be igonred.`
         Instead, the script will generate self-signed certificates and modify json config.`
         Please don't apply the same settings in Production Environment."

        # Install Server Cert and Client Cert locally and export.
        $thumbprintArray = InstallCertToLocal -CertSetupScript $CertSetupScript
        $serverThumbprint = $thumbprintArray[0]
        $clientThumbprint = $thumbprintArray[1]

        $packageRoot = (Get-Item $DeployerBinPath).parent.FullName
        $serverCertificate = ExportCertificateToLocal -PackageRoot $packageRoot -CertSetupScript $CertSetupScript -ServerThumbprint $ServerThumbprint -ClientThumbprint $clientThumbprint -ClusterConfigFilePath $ClusterConfigFilePath
                    
        # Install Cert Remotely
        if (-Not (IsOneBox -ClusterConfigFilePath $ClusterConfigFilePath))
        {
            InstallCertToRemote -ClusterConfigFilePath $ClusterConfigFilePath -CertificatePath $serverCertificate[0] -Password $serverCertificate[1]
        }        

        # Modify Json
        if ($GeneratedX509CertClusterConfigPath -eq $null)
        {
            $OutputConfigFolder = Join-Path $packageRoot "TemporaryConfig"
            if (-Not(Test-Path $OutputConfigFolder))
            {
                New-Item -ItemType Directory -Force -Path $OutputConfigFolder > $null
            }

            $GeneratedX509CertClusterConfigPath = Join-Path $OutputConfigFolder "GeneratedX509CertClusterConfig.json"
        }

        ModifyJsonThumbprint -ClusterConfigFilePath $ClusterConfigFilePath -ServerThumbprint $serverThumbprint -ClientThumbprint $clientThumbprint -OutPutPath $GeneratedX509CertClusterConfigPath
        $ClusterConfigFilePath = $GeneratedX509CertClusterConfigPath

        Write-Warning "Using generated $ClusterConfigFilePath to setup cluster. Please use it when removing cluster."
    }
    else 
    {
        Write-Warning 'Self-Signed certificates are not generated because X509 is not properly configured.'
    }
}

$parentVerbosePreference = $VerbosePreference

# Invoke in separate AppDomain
$argList = @($DeployerBinPath, $ServiceFabricPowershellModulePath, $ClusterConfigFilePath, $Force.IsPresent, $NoCleanupOnFailure.IsPresent, $MicrosoftServiceFabricCabFileAbsolutePath, $MaxPercentFailedNodes, $TimeoutInSeconds, $parentVerbosePreference)
Powershell -Command {
    param (
        [Parameter(Mandatory=$true)]
        [string] $DeployerBinPath,

        [Parameter(Mandatory=$true)]
        [string] $ServiceFabricPowershellModulePath,

        [Parameter(Mandatory=$true)]
        [string] $ClusterConfigFilePath,

        [Parameter(Mandatory=$false)]
        [bool] $Force,

        [Parameter(Mandatory=$false)]
        [bool] $NoCleanupOnFailure,

        [Parameter(Mandatory=$false)]
        [string] $MicrosoftServiceFabricCabFileAbsolutePath,

        [Parameter(Mandatory=$false)]
        [int] $MaxPercentFailedNodes,

        [Parameter(Mandatory=$false)]
        [int] $TimeoutInSeconds,

        [Parameter(Mandatory=$false)]
        [string] $parentVerbosePreference
    )

    #Add FabricCodePath Environment Path
    $env:path = "$($DeployerBinPath);" + $env:path

    #Import Service Fabric Powershell Module
    Import-Module $ServiceFabricPowershellModulePath

    #Download Runtime Package
    if(!$MicrosoftServiceFabricCabFileAbsolutePath)
    {
        Try
        {
            $RuntimePackageDetails = Get-ServiceFabricRuntimeSupportedVersion -Latest
            $RuntimeCabFilename = "MicrosoftAzureServiceFabric." + $RuntimePackageDetails.GoalRuntimeVersion + ".cab"
            $DeploymentPackageRoot = Split-Path -parent $DeployerBinPath
            $RuntimeBinPath = Join-Path $DeploymentPackageRoot -ChildPath "DeploymentRuntimePackages"
            $MicrosoftServiceFabricCabFilePath = Join-Path $RuntimeBinPath -ChildPath $RuntimeCabFilename
            if(!(Test-Path $MicrosoftServiceFabricCabFilePath)) 
            {
                $Version = $RuntimePackageDetails.GoalRuntimeVersion
                Write-Host "Runtime package version $Version was not found in DeploymentRuntimePackages folder and needed to be downloaded."
                (New-Object System.Net.WebClient).DownloadFile($RuntimePackageDetails.GoalRuntimeLocation, $MicrosoftServiceFabricCabFilePath)
                Write-Host "Runtime package has been successfully downloaded to $MicrosoftServiceFabricCabFilePath."
            }
            $MicrosoftServiceFabricCabFileAbsolutePath = Resolve-Path $MicrosoftServiceFabricCabFilePath
        }
        Catch
        {
            Write-Host "Runtime package cannot be downloaded. Check you internet connectivity. If the cluster is not connected to the internet, use another machine with internet connectivity to download the runtime package. Run DownloadServiceFabricRuntimePackage.ps1 -FabricRuntimePackageOutputDirectory <Path to directory where runtime package should be saved> to download the latest package. Then run CreateServiceFabricCluster.ps1 -ClusterConfigurationFilePath <ClusterConfigFilePath> -FabricRuntimePackagePath <RuntimePackagePath> to create the cluster. Exception thrown : $($_.Exception.ToString())" -ForegroundColor Red
            exit 1
        }
    }

    #Create a cluster
    Try 
    {
        $VerbosePreference = $parentVerbosePreference
        $params = @{ 
                        'ClusterConfigurationFilePath' = $ClusterConfigFilePath;
                        'FabricRuntimePackagePath' = $MicrosoftServiceFabricCabFileAbsolutePath;
                        'NoCleanupOnFailure' = $NoCleanupOnFailure;
                        'Force' = $Force;
                        'MaxPercentFailedNodes' = $MaxPercentFailedNodes;
                        'TimeoutInSeconds' = $TimeoutInSeconds;
                    }

        New-ServiceFabricCluster @params     
    }
    Catch
    {
        if($VerbosePreference -eq "SilentlyContinue")
        {
            Write-Host "Create Cluster failed. Call with -Verbose for more details" -ForegroundColor Red
        }
        exit 1
    }

} -args $argList -OutputFormat Text

$env:Path = [System.Environment]::GetEnvironmentVariable("path","Machine")

# SIG # Begin signature block
# MIIdjwYJKoZIhvcNAQcCoIIdgDCCHXwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7IN/nGXQCyThms8DpyjOSsoc
# 5N2gghhTMIIEwjCCA6qgAwIBAgITMwAAALwLLhp7irHHkQAAAAAAvDANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwOTA3MTc1ODQ3
# WhcNMTgwOTA3MTc1ODQ3WjCBsjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEMMAoGA1UECxMDQU9DMScwJQYDVQQLEx5uQ2lwaGVyIERTRSBFU046
# MTJCNC0yRDVGLTg3RDQxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNl
# cnZpY2UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCrW5IBRZQaAQPT
# HTCSXDRgGi/lbqVTqt3Mp5XqqbEkIZowQp8M/Gyv+1TmRpbFaQIQ4oQ7AqZRsvd+
# PMGtZjo6vUBRyeLKpnHq1a9XYeiGkoGaJu/98Ued3Z+sFD45bhzi6tLzY6kq98KI
# YqK7XsI76kqVU3oIyiETzzoANwuXUNSnm9lAN3l/G8xgDm/3qBWMSjkBvg2GeZ57
# 3WqYP6fImkO9U0bRtuIr6mybzvXUUO+rg6hhdrEnLGI4QQ7frEWReYeyMlgjC7VR
# aJy2gomkh+sEmxxivphgOuJrtPgUhdIlyTkUTtyudNUd/6gTE4zt9TsmFf5wGCsx
# pbZqKFW3AgMBAAGjggEJMIIBBTAdBgNVHQ4EFgQUyHJk5pJfz0FWFyn1nlRJFHyq
# /vcwHwYDVR0jBBgwFoAUIzT42VJGcArtQPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJ
# oEegRYZDaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMv
# TWljcm9zb2Z0VGltZVN0YW1wUENBLmNybDBYBggrBgEFBQcBAQRMMEowSAYIKwYB
# BQUHMAKGPGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9z
# b2Z0VGltZVN0YW1wUENBLmNydDATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG
# 9w0BAQUFAAOCAQEAPiS9UtetZjCdEkaanFlC+NU/Ti+PUD6O+P6yCASPI6+qK20t
# B16FXJg7rXRee3c/E2wcyWuxeL/0oLkj4LunxQoDDhoOjM9w9SnrWjki/kbkEdbg
# i1Pl4ebDSu+6Six3fdRrLowgkQwXxkCoUWwyFS9dL5BbC5lSzHlOiXiWVlc94vr3
# 9sMaoqsxl6A6Ud9YvbohYuiKJsdpSrLW97wXO66h+Cx289JckOmomW1Zum3ppfgp
# +5lJJBxySomU08S8G5QOOrvjO4KsQ55eHHVWJXhnGL+zhghaSf5TIQuDdohDOnNb
# +FImqnwn3++hmpbkAVWdFUNDNlJemia/hMH9vzCCBgAwggPooAMCAQICEzMAAADD
# Dpun2LLc9ywAAAAAAMMwDQYJKoZIhvcNAQELBQAwfjELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2ln
# bmluZyBQQ0EgMjAxMTAeFw0xNzA4MTEyMDIwMjRaFw0xODA4MTEyMDIwMjRaMHQx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xHjAcBgNVBAMTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBALtX1zjRsQZ/SS2pbbNjn3q6tjohW7SYro3UpIGgxXXFLO+CQCq3gVN382MB
# CrzON4QDQENXgkvO7R+2/YBtycKRXQXH3FZZAOEM61fe/fG4kCe/dUr8dbJyWLbF
# SJszYgXRlZSlvzkirY0STUZi2jIZzqoiXFZIsW9FyWd2Yl0wiKMvKMUfUCrZhtsa
# ESWBwvT1Zy7neR314hx19E7Mx/znvwuARyn/z81psQwLYOtn5oQbm039bUc6x9nB
# YWHylRKhDQeuYyHY9Jkc/3hVge6leegggl8K2rVTGVQBVw2HkY3CfPFUhoDhYtuC
# cz4mXvBAEtI51SYDDYWIMV8KC4sCAwEAAaOCAX8wggF7MB8GA1UdJQQYMBYGCisG
# AQQBgjdMCAEGCCsGAQUFBwMDMB0GA1UdDgQWBBSnE10fIYlV6APunhc26vJUiDUZ
# rzBRBgNVHREESjBIpEYwRDEMMAoGA1UECxMDQU9DMTQwMgYDVQQFEysyMzAwMTIr
# YzgwNGI1ZWEtNDliNC00MjM4LTgzNjItZDg1MWZhMjI1NGZjMB8GA1UdIwQYMBaA
# FEhuZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFf
# MjAxMS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEA
# TZdPNH7xcJOc49UaS5wRfmsmxKUk9N9E1CS6s2oIiZmayzHncJv/FB2wBzl/5DA7
# EyLeDsiVZ7tufvh8laSQgjeTpoPTSQLBrK1Z75G3p2YADqJMJdTc510HAsooNGU7
# OYOtlSqOyqDoCDoc/j57QEmUTY5UJQrlsccK7nE3xpteNvWnQkT7vIewDcA12SaH
# X/9n7yh094owBBGKZ8xLNWBqIefDjQeDXpurnXEfKSYJEdT1gtPSNgcpruiSbZB/
# AMmoW+7QBGX7oQ5XU8zymInznxWTyAbEY1JhAk9XSBz1+3USyrX59MJpX7uhnQ1p
# gyfrgz4dazHD7g7xxIRDh+4xnAYAMny3IIq5CCPqVrAY1LK9Few37WTTaxUCI8aK
# M4c60Zu2wJZZLKABU4QBX/J7wXqw7NTYUvZfdYFEWRY4J1O7UPNecd/311HcMdUa
# YzUql36fZjdfz1Uz77LKvCwjqkQe7vtnSLToQsMPilFYokYCYSZaGb9clOmoQHDn
# WzBMfIDUUGeipe4O6z218eV5HuH1WBlvu4lteOIgWCX/5Eiz5q/xskAEF0ZQ1Axs
# kRR97sri9ibeGzsEZ1EuD6QX90L/P5GJMfinvLPlOlLcKjN/SmSRZdhlEbbbare0
# bFL8v4txFsQsznOaoOldCMFFRaUphuwBMW1edMZWMQswggYHMIID76ADAgECAgph
# Fmg0AAAAAAAcMA0GCSqGSIb3DQEBBQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20x
# GTAXBgoJkiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBS
# b290IENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0
# MDMxMzAzMDlaMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# ITAfBgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAJ+hbLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP
# 7tGn0UytdDAgEesH1VSVFUmUG0KSrphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySH
# nfL0Zxws/HvniB3q506jocEjU8qN+kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUo
# Ri4nrIZPVVIM5AMs+2qQkDBuh/NZMJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABK
# R2YRJylmqJfk0waBSqL5hKcRRxQJgp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSf
# rx54QTF3zJvfO4OToWECtR0Nsfz3m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGn
# MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMP
# MAsGA1UdDwQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQO
# rIJgQFYnl+UlE/wq4QpTlVnkpKFjpGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZ
# MBcGCgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJv
# b3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1Ud
# HwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3By
# b2R1Y3RzL21pY3Jvc29mdHJvb3RjZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYI
# KwYBBQUHMAKGOGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWlj
# cm9zb2Z0Um9vdENlcnQuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3
# DQEBBQUAA4ICAQAQl4rDXANENt3ptK132855UU0BsS50cVttDBOrzr57j7gu1BKi
# jG1iuFcCy04gE1CZ3XpA4le7r1iaHOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV
# 3U+rkuTnjWrVgMHmlPIGL4UD6ZEqJCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5
# nGctxVEO6mJcPxaYiyA/4gcaMvnMMUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tO
# i3/FNSteo7/rvH0LQnvUU3Ih7jDKu3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbM
# UVbonXCUbKw5TNT2eb+qGHpiKe+imyk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXj
# pKh0NbhOxXEjEiZ2CzxSjHFaRkMUvLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh
# 0EPpK+m79EjMLNTYMoBMJipIJF9a6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLax
# aj2JoXZhtG6hE6a/qkfwEm/9ijJssv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWw
# ymO0eFQF1EEuUKyUsKV4q7OglnUa2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma
# 7kng9wFlb4kLfchpyOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TCCB3ow
# ggVioAMCAQICCmEOkNIAAAAAAAMwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBS
# b290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoX
# DTI2MDcwODIxMDkwOVowfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLry
# tlghn0IbKmvpWlCquAY4GgRJun/DDB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlk
# h36UYCRsr55JnOloXtLfm1OyCizDr9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sI
# UM+zRLdd2MQuA3WraPPLbfM6XKEW9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5
# pUkp5w2+oBN3vpQ97/vjK1oQH01WKKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd
# 6IlPhBryoS9Z5JA7La4zWMW3Pv4y07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9T
# upwPrRkjhMv0ugOGjfdf8NBSv4yUh7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOn
# qWbsYR9q4ShJnV+I4iVd0yFLPlLEtVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKC
# X9vAFbO9G9RVS+c5oQ/pI0m8GLhEfEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkw
# p6uO3+xbn6/83bBm4sGXgXvt1u1L50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo
# 8e1twyiPLI9AN0/B4YVEicQJTMXUpUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96e
# TvSWsLxGoGyY0uDWiIwLAgMBAAGjggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAd
# BgNVHQ4EFgQUSG5k5VAF04KqFzc3IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBT
# AHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgw
# FoAUci06AjGQQ7kUBU7h6qfHMdEjiTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDov
# L2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0
# MjAxMV8yMDExXzAzXzIyLmNybDBeBggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKG
# Qmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0
# MjAxMV8yMDExXzAzXzIyLmNydDCBnwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMw
# gYMwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# ZG9jcy9wcmltYXJ5Y3BzLmh0bTBABggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwA
# XwBwAG8AbABpAGMAeQBfAHMAdABhAHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0B
# AQsFAAOCAgEAZ/KGpZjgVHkaLtPYdGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy
# 0W2D/r4/6ArKO79HqaPzadtjvyI1pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9
# a+M+By4pm+Y9G6XUtR13lDni6WTJRD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUM
# m+1o+mgulaAqPyprWEljHwlpblqYluSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMO
# r5kol5hNDj0L8giJ1h/DMhji8MUtzluetEk5CsYKwsatruWy2dsViFFFWDgycSca
# f7H0J/jeLDogaZiyWYlobm+nt3TDQAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWn
# duVAKmWjw11SYobDHWM2l4bf2vP48hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1
# HxS+YWG18NzGGwS+30HHDiju3mUv7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnF
# sZulP0V3HjXG0qKin3p6IvpIlR+r+0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9az
# I2h15q/6/IvrC4DqaTuv/DDtBEyO3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/
# +6jMpF3BoYibV3FWTkhFwELJm3ZbCoBIa/15n8G9bW1qyVJzEw16UM0xggSmMIIE
# ogIBATCBlTB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgw
# JgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExAhMzAAAAww6b
# p9iy3PcsAAAAAADDMAkGBSsOAwIaBQCggbowGQYJKoZIhvcNAQkDMQwGCisGAQQB
# gjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkE
# MRYEFFhI4HnpCq8yW9nEM8wu526+pEGtMFoGCisGAQQBgjcCAQwxTDBKoCSAIgBN
# AGkAYwByAG8AcwBvAGYAdAAgAFcAaQBuAGQAbwB3AHOhIoAgaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3dpbmRvd3MwDQYJKoZIhvcNAQEBBQAEggEARgoZrU1lv3m5
# RnCevRI3eH54TpKu2yfXIwJlLNyxWTOdjf6Y6+zbTk9uM/HTvUUV2hSi8rsSbaaI
# u1am0dw1ctrMn9D9Ivx97tUwkV5IYnIuvSfpOQFGxgzID2OHrrQiU5mVwcjowwB6
# eMlVUKgNk3mr3VRzvrtiXq3O7c2IZLTPiqcRRCrIelfdrXaTTf06FF9lGuIz6eC4
# WKADHpbhT4gQvHGP8sAlTBiaKHWh957ko/NEUBdL39GzwM1lw8Mehhim357xdPkE
# qpbQ15Krr620gBRPfmorc/GyaVB6/T1A4/AyltHSZjQkFnkD01gViczKs4+rP5J0
# p5te+b+KUaGCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBQQ0ECEzMAAAC8Cy4ae4qxx5EAAAAAALwwCQYFKw4DAhoF
# AKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE4
# MDMyMTAyMjUwMFowIwYJKoZIhvcNAQkEMRYEFN7n8RC3iBD1dlbwZcWf9l1RHc+A
# MA0GCSqGSIb3DQEBBQUABIIBAIglKd494cgJpEzkC+X/YAxwKR0mpC72MMcGDwEP
# u701EBCpIWAsPMGatqDzommjtkwZS1V821kUzc3PP4vQct1A6kvw+jbh/xtmM/Kh
# yo2hLu0bDkVR8VhDBkRnPlqlja0LHOf/2sliyW/s8xgO0uZevlyHoauhRCZEITIc
# SMYJoI+gIxQaG8zKNTZDi4TdzVtvZnNHEMmfZ3TkkU83SOnhfpEXLN8ZtEZgKMwD
# XvryRIVAhQ89i7rarLrPGvtPn4DcwgC/urA/IrS2FToaHYmrt4YouDw2OzkCcaaW
# XnekI3ZsiPGFSE+WeSOKS8vM1MK6f9C8wEXveO9aAjddRu0=
# SIG # End signature block
