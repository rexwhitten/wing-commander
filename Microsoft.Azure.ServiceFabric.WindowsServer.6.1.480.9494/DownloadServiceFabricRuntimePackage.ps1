param (
    [Parameter(Mandatory=$true)]
    [string] $FabricRuntimePackageOutputDirectory
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

$ServiceFabricPowershellModulePath = Join-Path $DeployerBinPath -ChildPath "ServiceFabric.psd1"

$FabricRuntimePackageOutputDirectoryAbsolutePath = Resolve-Path $FabricRuntimePackageOutputDirectory
if(!(Test-Path $FabricRuntimePackageOutputDirectoryAbsolutePath)) 
{
	Write-Host "Output directory specified does not exist."
	exit 1
}

# Invoke in separate AppDomain
$argList = @($DeployerBinPath, $ServiceFabricPowershellModulePath, $FabricRuntimePackageOutputDirectoryAbsolutePath)
Powershell -Command {
    param (
        [Parameter(Mandatory=$true)]
        [string] $DeployerBinPath,

        [Parameter(Mandatory=$true)]
        [string] $ServiceFabricPowershellModulePath,

        [Parameter(Mandatory=$true)]
        [string] $FabricRuntimePackageOutputDirectoryAbsolutePath
    )

    #Add FabricCodePath Environment Path
    $env:path = "$($DeployerBinPath);" + $env:path

    #Import Service Fabric Powershell Module
    Import-Module $ServiceFabricPowershellModulePath

    #Download Runtime Package
    Try
    {
        $RuntimePackageDetails = Get-ServiceFabricRuntimeSupportedVersion -Latest
        $RuntimeCabFilename = "MicrosoftAzureServiceFabric." + $RuntimePackageDetails.GoalRuntimeVersion + ".cab"
        $MicrosoftServiceFabricCabFilePath = Join-Path $FabricRuntimePackageOutputDirectoryAbsolutePath -ChildPath $RuntimeCabFilename
        if(!(Test-Path $MicrosoftServiceFabricCabFilePath)) 
        {
           $Version = $RuntimePackageDetails.GoalRuntimeVersion
           Write-Host "Runtime package version $Version was not found in DeploymentRuntimePackages folder and needed to be downloaded."
           (New-Object System.Net.WebClient).DownloadFile($RuntimePackageDetails.GoalRuntimeLocation, $MicrosoftServiceFabricCabFilePath)
           Write-Host "Runtime package has been successfully downloaded to $MicrosoftServiceFabricCabFilePath."
        }
        Resolve-Path $MicrosoftServiceFabricCabFilePath
    }
    Catch
    {
        Write-Host "Runtime package cannot be downloaded. Check you internet connectivity. If the cluster is not connected to the internet use DownloadServiceFabricRuntimePackage.ps1 script to download the latest package. Then run CreateServiceFabricCluster.ps1 -ClusterConfigurationFilePath <ClusterConfigFilePath> -FabricRuntimePackagePath <RuntimePackagePath> to create the cluster. Exception thrown : $($_.Exception.ToString())" -ForegroundColor Red
        exit 1
    }  
} -args $argList -OutputFormat Text

$env:Path = [System.Environment]::GetEnvironmentVariable("path","Machine")

# SIG # Begin signature block
# MIIdjgYJKoZIhvcNAQcCoIIdfzCCHXsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUV2wmJkGUg6aOa5XKb6ZzbILB
# 9RugghhSMIIEwTCCA6mgAwIBAgITMwAAANjkdflFb0j3rgAAAAAA2DANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTcxMDAyMjI1NzU3
# WhcNMTkwMTAyMjI1NzU3WjCBsTELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEMMAoGA1UECxMDQU9DMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo3
# MERELTRCNUItNDU2ODElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMR2sf6C9y+kIdyj
# 16QouyVvlvPjzdmE1FFIAb7gUl7UCknd2nlquXeGJHQdX22zmY18QH/8EjH8voTu
# 57DqKJRFkqkD+PQ87+M4j2aW27QCHiHVATEHdHelT0ANUSoxETlAe4d6gd6sL/aA
# wkqFSqTncLfVeAenMJ7Te3tLmLYBk59CI/Tmf2YCsU+Z0nQ0S0AH6IHAKbDLLUPZ
# 1KW4d5Mmig1YMInsaoDHJvmuXyUZ6GxluZ7GX+WxF2XoxFRuMo6OWrCER3gnx/W3
# omzHOc1/C/oBI8hELBQH8uTJYqI8iGx8yqDyYETHoZNdH0oFeIOfAvVFlUYTE3JW
# pbMtF0cCAwEAAaOCAQkwggEFMB0GA1UdDgQWBBSgHm6PHyXdykNng5Up+ne9UdYe
# VjAfBgNVHSMEGDAWgBQjNPjZUkZwCu1A+3b7syuwwzWzDzBUBgNVHR8ETTBLMEmg
# R6BFhkNodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9N
# aWNyb3NvZnRUaW1lU3RhbXBQQ0EuY3JsMFgGCCsGAQUFBwEBBEwwSjBIBggrBgEF
# BQcwAoY8aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNyb3Nv
# ZnRUaW1lU3RhbXBQQ0EuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3
# DQEBBQUAA4IBAQCFDewTPdV6/bMFMK0kqgvI8Y7t1YvHrGmvpdA/Y2zx+ERd0g9d
# ENtHTlfAPC1X15YlDXZNPdo7LY6wMJco/rXcjzFZ/tIvGHcIaQE52tJKW+pmXfrv
# QWW4X3pQdbPTsCwcDSGPcDImnec0dathWPicWxBg1NIeSDDsdsqpESp0kSs9g9fL
# QWUi9wHlFehburgOJCWpQ1jkNspUvJ7xMmtTTEIu6WPEDGHU8LxHraClsL0/BzPN
# KE85uB3+5/yOurKU/V8kH/obxzB03XxI4QpbpU1D2yasOd7JVmCGEbHBRamtHVz6
# SnVVVviJUsoGV5/jdzHuXyUIy9LKSUwuTdykMIIGADCCA+igAwIBAgITMwAAAMMO
# m6fYstz3LAAAAAAAwzANBgkqhkiG9w0BAQsFADB+MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWdu
# aW5nIFBDQSAyMDExMB4XDTE3MDgxMTIwMjAyNFoXDTE4MDgxMTIwMjAyNFowdDEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEeMBwGA1UEAxMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEAu1fXONGxBn9JLalts2Oferq2OiFbtJiujdSkgaDFdcUs74JAKreBU3fzYwEK
# vM43hANAQ1eCS87tH7b9gG3JwpFdBcfcVlkA4QzrV9798biQJ791Svx1snJYtsVI
# mzNiBdGVlKW/OSKtjRJNRmLaMhnOqiJcVkixb0XJZ3ZiXTCIoy8oxR9QKtmG2xoR
# JYHC9PVnLud5HfXiHHX0TszH/Oe/C4BHKf/PzWmxDAtg62fmhBubTf1tRzrH2cFh
# YfKVEqENB65jIdj0mRz/eFWB7qV56CCCXwratVMZVAFXDYeRjcJ88VSGgOFi24Jz
# PiZe8EAS0jnVJgMNhYgxXwoLiwIDAQABo4IBfzCCAXswHwYDVR0lBBgwFgYKKwYB
# BAGCN0wIAQYIKwYBBQUHAwMwHQYDVR0OBBYEFKcTXR8hiVXoA+6eFzbq8lSINRmv
# MFEGA1UdEQRKMEikRjBEMQwwCgYDVQQLEwNBT0MxNDAyBgNVBAUTKzIzMDAxMitj
# ODA0YjVlYS00OWI0LTQyMzgtODM2Mi1kODUxZmEyMjU0ZmMwHwYDVR0jBBgwFoAU
# SG5k5VAF04KqFzc3IrVtqMp1ApUwVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljQ29kU2lnUENBMjAxMV8yMDEx
# LTA3LTA4LmNybDBhBggrBgEFBQcBAQRVMFMwUQYIKwYBBQUHMAKGRWh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljQ29kU2lnUENBMjAxMV8y
# MDExLTA3LTA4LmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4ICAQBN
# l080fvFwk5zj1RpLnBF+aybEpST030TUJLqzagiJmZrLMedwm/8UHbAHOX/kMDsT
# It4OyJVnu25++HyVpJCCN5Omg9NJAsGsrVnvkbenZgAOokwl1NznXQcCyig0ZTs5
# g62VKo7KoOgIOhz+PntASZRNjlQlCuWxxwrucTfGm1429adCRPu8h7ANwDXZJodf
# /2fvKHT3ijAEEYpnzEs1YGoh58ONB4Nem6udcR8pJgkR1PWC09I2Bymu6JJtkH8A
# yahb7tAEZfuhDldTzPKYifOfFZPIBsRjUmECT1dIHPX7dRLKtfn0wmlfu6GdDWmD
# J+uDPh1rMcPuDvHEhEOH7jGcBgAyfLcgirkII+pWsBjUsr0V7DftZNNrFQIjxooz
# hzrRm7bAllksoAFThAFf8nvBerDs1NhS9l91gURZFjgnU7tQ815x3/fXUdwx1Rpj
# NSqXfp9mN1/PVTPvssq8LCOqRB7u+2dItOhCww+KUViiRgJhJloZv1yU6ahAcOdb
# MEx8gNRQZ6Kl7g7rPbXx5Xke4fVYGW+7iW144iBYJf/kSLPmr/GyQAQXRlDUDGyR
# FH3uyuL2Jt4bOwRnUS4PpBf3Qv8/kYkx+Ke8s+U6UtwqM39KZJFl2GURtttqt7Rs
# Uvy/i3EWxCzOc5qg6V0IwUVFpSmG7AExbV50xlYxCzCCBgcwggPvoAMCAQICCmEW
# aDQAAAAAABwwDQYJKoZIhvcNAQEFBQAwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZ
# MBcGCgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJv
# b3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTA3MDQwMzEyNTMwOVoXDTIxMDQw
# MzEzMDMwOVowdzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEh
# MB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAn6Fssd/bSJIqfGsuGeG94uPFmVEjUK3O3RhOJA/u
# 0afRTK10MCAR6wfVVJUVSZQbQpKumFwwJtoAa+h7veyJBw/3DgSY8InMH8szJIed
# 8vRnHCz8e+eIHernTqOhwSNTyo36Rc8J0F6v0LBCBKL5pmyTZ9co3EZTsIbQ5ShG
# Lieshk9VUgzkAyz7apCQMG6H81kwnfp+1pez6CGXfvjSE/MIt1NtUrRFkJ9IAEpH
# ZhEnKWaol+TTBoFKovmEpxFHFAmCn4TtVXj+AZodUAiFABAwRu233iNGu8QtVJ+v
# HnhBMXfMm987g5OhYQK1HQ2x/PebsgHOIktU//kFw8IgCwIDAQABo4IBqzCCAacw
# DwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUIzT42VJGcArtQPt2+7MrsMM1sw8w
# CwYDVR0PBAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMIGYBgNVHSMEgZAwgY2AFA6s
# gmBAVieX5SUT/CrhClOVWeSkoWOkYTBfMRMwEQYKCZImiZPyLGQBGRYDY29tMRkw
# FwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQDEyRNaWNyb3NvZnQgUm9v
# dCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHmCEHmtFqFKoKWtTHNY9AcTLmUwUAYDVR0f
# BEkwRzBFoEOgQYY/aHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJv
# ZHVjdHMvbWljcm9zb2Z0cm9vdGNlcnQuY3JsMFQGCCsGAQUFBwEBBEgwRjBEBggr
# BgEFBQcwAoY4aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNy
# b3NvZnRSb290Q2VydC5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcN
# AQEFBQADggIBABCXisNcA0Q23em0rXfbznlRTQGxLnRxW20ME6vOvnuPuC7UEqKM
# bWK4VwLLTiATUJndekDiV7uvWJoc4R0Bhqy7ePKL0Ow7Ae7ivo8KBciNSOLwUxXd
# T6uS5OeNatWAweaU8gYvhQPpkSokInD79vzkeJkuDfcH4nC8GE6djmsKcpW4oTmc
# Zy3FUQ7qYlw/FpiLID/iBxoy+cwxSnYxPStyC8jqcD3/hQoT38IKYY7w17gX606L
# f8U1K16jv+u8fQtCe9RTciHuMMq7eGVcWwEXChQO0toUmPU8uWZYsy0v5/mFhsxR
# VuidcJRsrDlM1PZ5v6oYemIp76KbKTQGdxpiyT0ebR+C8AvHLLvPQ7Pl+ex9teOk
# qHQ1uE7FcSMSJnYLPFKMcVpGQxS8s7OwTWfIn0L/gHkhgJ4VMGboQhJeGsieIiHQ
# Q+kr6bv0SMws1NgygEwmKkgkX1rqVu+m3pmdyjpvvYEndAYR7nYhv5uCwSdUtrFq
# PYmhdmG0bqETpr+qR/ASb/2KMmyy/t9RyIwjyWa9nR2HEmQCPS2vWY+45CHltbDK
# Y7R4VAXUQS5QrJSwpXirs6CWdRrZkocTdSIvMqgIbqBbjCW/oO+EyiHW6x5PyZru
# SeD3AWVviQt9yGnI5m7qp5fOMSn/DsVbXNhNG6HY+i+ePy5VFmvJE6P9MIIHejCC
# BWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJv
# b3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcN
# MjYwNzA4MjEwOTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2
# WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSH
# fpRgJGyvnkmc6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQ
# z7NEt13YxC4Ddato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHml
# SSnnDb6gE3e+lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3o
# iU+EGvKhL1nkkDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6
# nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6ep
# ZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf
# 28AVs70b1FVL5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCn
# q47f7Fufr/zdsGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx
# 7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O
# 9JawvEagbJjS4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0G
# A1UdDgQWBBRIbmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMA
# dQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAW
# gBRyLToCMZBDuRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8v
# Y3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQy
# MDExXzIwMTFfMDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZC
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQy
# MDExXzIwMTFfMDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCB
# gzA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9k
# b2NzL3ByaW1hcnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABf
# AHAAbwBsAGkAYwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEB
# CwUAA4ICAQBn8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LR
# bYP+vj/oCso7v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r
# 4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb
# 7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6v
# mSiXmE0OPQvyCInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/
# sfQn+N4sOiBpmLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad2
# 5UAqZaPDXVJihsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUf
# FL5hYbXw3MYbBL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWx
# m6U/RXceNcbSoqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMj
# aHXmr/r8i+sLgOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7
# qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCBKYwggSi
# AgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAm
# BgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAADDDpun
# 2LLc9ywAAAAAAMMwCQYFKw4DAhoFAKCBujAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQx
# FgQU/E7G2tWPmY/VkkNOqZ9m0URlknAwWgYKKwYBBAGCNwIBDDFMMEqgJIAiAE0A
# aQBjAHIAbwBzAG8AZgB0ACAAVwBpAG4AZABvAHcAc6EigCBodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vd2luZG93czANBgkqhkiG9w0BAQEFAASCAQCkz3QT6OjAGBmq
# XAlw82vAx9ofUrdQSqeY/x3rCVMFjy0UxGl0ksKjrR46RCALfkd6mKPsjlGNrwxC
# gK4oMyhbpVTHhcG13OQSGuKnFW6HLQqfdrLzr8KJlaqN2dlT4rb7O9YqNZ+PnHvr
# 8z35v3cmR0iiBogaAiwq+PZvpAbBusnDyG31FmzCd4voZmiKu4+I4VsXJ+e0P5GB
# FnsYE+3wnenzyVsRNFKJnpHDq7ydKsf17nMwJSSjFwO+WCj15DdYcLQn5VwgadHf
# ZcbbFiP4qe1pAdX88LixVw7hCz7nR/vofUYv/cN8rZAZLVFEg98ifRcddiSqOaFE
# +5P86Hc8oYICKDCCAiQGCSqGSIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQQITMwAAANjkdflFb0j3rgAAAAAA2DAJBgUrDgMCGgUA
# oF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTgw
# MzIxMDIyNTE4WjAjBgkqhkiG9w0BCQQxFgQU83VvW5CveyKgQy5Q2PmgRdHfqokw
# DQYJKoZIhvcNAQEFBQAEggEAL/p+buX41lQ9zfpWAd1S0NepcxRcJPLwK+qSTjrU
# XCNmVQd6Mg+T8kWgebqa7coRTPFKL4Ad66Z+GbCTT8LI59HNSb8n9fPfDPLvWj6V
# SFb2O9k39AvqTBE6bOPK32GunQo0hHhco/N4kkMkKRt9uPSWDXvS/0qNO74jHcfz
# aPCR9VsIVzeCGLu2wVcpU9SAqp3vlYbQGDp/GNx0NtDpIOf1HA82uWJw1k7oN4My
# 3sRRDZs7LXoLHZcU8QfVF6kVFiYePCxhw834IbVhuitjNqszVnH9gY/1Gzacj+c2
# xc/P+f91nvo/dHbx7XWyfGJBlyUL2Iel05D8FWNxJgzoSA==
# SIG # End signature block
