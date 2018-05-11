#
# Capability Functionss
#
Function Module-Installed {
    Param([string]$name) 
    if (Get-Module -ListAvailable | 
            Where-Object { $_.name -eq $name }) { 
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
    
    $user = "$($env:USERDOMAIN)\$($env:UserName)";

    if (!(Test-Path $path -PathType Container)) {
        Write-Host "[info]::msg:creating-directory:$path"
        New-Item -ItemType Directory `
            -Path $path `
            -Force  
    }
    Else {
        Write-Host "[info]::msg:removing-directory:$path"
        Remove-Item -Path $path `
            -Recurse `
            -Force
        Write-Host "[info]::msg:creating-directory:$path"
        New-Item -ItemType Directory `
            -Path $path `
            -Force  
    }

    # apply permissions 
    Try {
        $acl = Get-Acl -Path $path
        $permission = $user, 'Modify', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
        $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
        $acl.SetAccessRule($rule)
        $acl | Set-Acl -Path $path
    }
    Catch {
        Write-Host "Reset-Directory:: Error apply permissions to $path, moving on..."
    }
}

Function Test-RegistryPath {

    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$path
    )
    
    Test-Path -Path $path
}

Function Download {
    
    param (
        [string]$url,
        [string]$dir
    )

    Write-Host "Downloading $url"

    Invoke-WebRequest -Uri $url -OutFile $dir
}

Function Unpack-Cab {
    
    param (
        [string]$cab_file,
        [string]$output_dir
    )

    $exp_exe = "expand"
    $exp_exe_args = "-R $cab_file $output_dir"
    Invoke-Expression "$exp_exe $exp_exe_args"
}

Function Find-Latest {
    param(
        [string]$dir
    )
    Write-Host "Searching for latest file in "
    $latest = Get-ChildItem -Path $dir | Sort-Object LastAccessTime -Descending | Select-Object -First 1
    return $latest.Name
}

Function Test-Permission {
    Param(
        [string]$Folder
    )

    $User = "$($env:USERDOMAIN)\$($env:UserName)";

    return (Get-Acl $Folder).Access | Where-Object {$_.IdentityReference -match $User} | Select-Object IdentityReference, FileSystemRights
}

Function Test-Admin {
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    $IsAdmin = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

    if (!$IsAdmin) {
        Write-host "Please run the script with administrative privileges." -ForegroundColor "Red"
        exit 1
    }
}