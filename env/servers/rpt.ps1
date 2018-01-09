# 
# report server setup script
# =======================
#
#

# Variables
# -----------------------
$env:SERVER_TYPE = "report";
$env:SI_ENV = "DEV";

# Ports
# -----------------------

# Users  
# -----------------------
New-LocalUser -Name "report01" -Description "report account" -NoPassword
Add-LocalGroupMember -Group "Administrators" -Member "report01"

# Install Packages
# -----------------------

# Scheduled Tasks   
# -----------------------# Report server setup scripts 
