# 
# monitor server setup script
# =======================
#
#

# Variables
# -----------------------
$env:SERVER_TYPE = "monitor";
$env:SI_ENV = "DEV";

# Ports
# -----------------------

# Users  
# -----------------------
New-LocalUser -Name "monitor01" -Description "monitor account" -NoPassword
Add-LocalGroupMember -Group "Administrators" -Member "monitor01"

# Install Packages
# -----------------------

# Scheduled Tasks   
# -----------------------