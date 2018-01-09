# 
# director server setup script
# =======================
#
#

# Variables
# -----------------------
$env:TestVariable = "This is a test environment variable."

# Ports
# -----------------------
New-NetFirewallRule -DisplayName 'HTTP(S) Inbound' -Profile @('Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('80', '443')

# Users  
# -----------------------
New-LocalUser -Name "Director01" -Description "director account" -NoPassword
Add-LocalGroupMember -Group "Administrators" -Member "Director01"

# Install Packages
# -----------------------

# Scheduled Tasks   
# -----------------------