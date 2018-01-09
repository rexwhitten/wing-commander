# 
# director server setup script
# =======================
#
#

# Variables
# -----------------------
$env:SERVER_TYPE = "DIRECTOR";
$env:SI_ENV = "DEV";

# Ports
# -----------------------

# Users  
# -----------------------
New-LocalUser -Name "Director01" -Description "director account" -NoPassword
Add-LocalGroupMember -Group "Administrators" -Member "Director01"

# Install Packages
# -----------------------

# Scheduled Tasks   
# -----------------------