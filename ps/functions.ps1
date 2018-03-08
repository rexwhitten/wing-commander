
Function Module-Installed {
    Param([string]$name) 
    if(Get-Module -ListAvailable | 
       Where-Object { $_.name -eq $name }) 
    { 
        return $true 
    } #end if module available then import
    return $false;
}

Function Create-Directory {
    Param([string]$path) 
    if (!(Test-Path $path -PathType Container)) {
        New-Item -ItemType Directory `
        -Path $path `
        -Force  
    }
}

Function Reset-Directory {
    Param([string]$path) 
    if (!(Test-Path $path -PathType Container)) {
        New-Item -ItemType Directory `
                 -Path $path `
                 -Force  
    } Else {
        Remove-Item -Path $path `
                    -Recurse `
                    -Force
        New-Item -ItemType Directory `
                 -Path $path `
                 -Force  
    }
}

function Test-RegistryPath {

    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$path
    )
    
    Test-Path -Path $path
}