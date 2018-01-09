# --------------------------------------------
# MX Environment Setup 
# Creates a single pipeline environment
# --------------------------------------------
# (Get-Content JsonFile.JSON) -join "`n" | ConvertFrom-Json
# Cleanup Environment

# Setup Director Server 
.\container\build.ps1 `
    -server  "dev1director" `
    -script ".\env\servers\director.ps1"  `
    -image  "microsoft/windowsservercore" `
    -type_name "ServerCore"