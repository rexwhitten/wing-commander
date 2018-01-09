# 
# sql server setup script
# =======================
#
#

# Variables
# -----------------------
$env:SERVER_TYPE = "sql";
$env:SI_ENV = "DEV";

# Ports
# -----------------------

# Users  
# -----------------------
New-LocalUser -Name "sql01" -Description "sql account" -NoPassword
Add-LocalGroupMember -Group "Administrators" -Member "sql01"



# Install Packages
# -----------------------

# Scheduled Tasks   
# -----------------------