# --------------------------------------------
# MX Environment Setup 
# Creates a single pipeline environment
# --------------------------------------------
# (Get-Content JsonFile.JSON) -join "`n" | ConvertFrom-Json
# Cleanup Environment

# Setup Director Server 
.\container\build.ps1 `
    -container_name  "DEVCOREDIRECTOR1" `
    -script ".\env\servers\director.ps1"  `
    -machine_script ".\env\types\core\core.ps1" `
    -image  "microsoft/windowsservercore" `
    -machine_name "DEVCOREDIRECTOR1"