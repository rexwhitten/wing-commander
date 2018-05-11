# Install 
# This script should uninstall and install. 
# This script should work on a developers laptop
# This script should install everything needed 
# We should be able to run this script several times in a row, without issue

# --------------------------------------------------------------------------
. ".\ps\functions.ps1"
$ErrorActionPreference = "Stop"
$temp_path = "C:\temp"

$ascii_art = "
(_) _     _ (_)(_)_       _(_)   
(_)(_)   (_)(_)  (_)_   _(_)     
(_) (_)_(_) (_)    (_)_(_)       
(_)   (_)   (_)     _(_)_        
(_)         (_)   _(_) (_)_      
(_)         (_) _(_)     (_)_    
(_)         (_)(_)         (_)      
";

Write-Host $ascii_art
Write-Host "[begin]::\install.ps1";

#Reset-Directory -path "C:\mx"
#Reset-Directory -path "C:\mx\sf"
Reset-Directory -path "C:\mx\containers"
Reset-Directory -path "C:\mx\data"
Reset-Directory -path "C:\mx\log"

# Service fabric - ".\cluster\install.ps1", 
$install_scripts = @(
    ".\sys\install.ps1",
    ".\container\install.ps1",
    ".\cluster\install.ps1",
    ".\env\install.ps1"
)

For ($i = 0; $i -le $install_scripts.Count; $i++) {
    $install_script = $install_scripts[$i];
    if ($install_script -eq $null) {
        
    }
    Else {
        Write-Progress -Activity  "Running script $install_script" `
            -Status "installing.." `
            -PercentComplete ($i / $install_scripts.Count * 100)
        # Invoke-Expression -Command $install_script;
        Invoke-Expression "powershell $install_script -NoExit"
    }
}

Write-Host "[end]::\install.ps1";