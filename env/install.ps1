# Install 
# This script should uninstall and install. 
# This script should work on a developers laptop
# This script should install everything needed 
# We should be able to run this script several times in a row, without issue
# *** THIS SCRIPT ONLY INSTALLS SYS DEPENDENCIES NOT SOURCE CONTROLLED CODE ***
# --------------------------------------------------------------------------
$ErrorActionPreference = "Stop"
$temp_path = "C:\temp"

$ascii_art = "
_           _  _           _    
(_) _     _ (_)(_)_       _(_)   
(_)(_)   (_)(_)  (_)_   _(_)     
(_) (_)_(_) (_)    (_)_(_)       
(_)   (_)   (_)     _(_)_        
(_)         (_)   _(_) (_)_      
(_)         (_) _(_)     (_)_    
(_)         (_)(_)         (_)   
                                 
";

Write-Host $ascii_art
Write-Progress -Activity "Begin Installation..." `
    -Status "ok" `
    -PercentComplete (0)

$install_scripts = @(
    ".\env\sys.ps1",
    ".\env\choco.ps1",
    ".\env\docker.ps1",
    ".\env\sf.ps1"
)

For($i =0;$i -le $install_scripts.Count; $i++) {
    $install_script = $install_scripts[$i];
    if ($install_script -eq $null) {
        
    } Else {
        Write-Progress -Activity  "Running script $install_script" `
                       -Status "..installing.." `
                       -PercentComplete ($i / $install_scripts.Count * 100)
        Invoke-Expression -Command $install_script;
    }
}

# Create Local Empty Cluster 
.\cluster\build.ps1