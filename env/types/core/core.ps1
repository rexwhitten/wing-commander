#
# core server setup 
#

# system
#netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes


# Variables
# -----------------------
$env:SYS_SERVER_TYPE = "microsoft/servercore"

# Firewall / Ports
# -----------------------
# netsh advfirewall set allprofiles state on
# Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
# New-NetFirewallRule -DisplayName 'HTTP(S) Inbound' -Profile @('Public','Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('80', '443')


# Users  
# -----------------------
New-LocalUser -Name "LocalSys" -Description "director account" -NoPassword
Add-LocalGroupMember -Group "Administrators" -Member "LocalSys"

# Install Package Software
# -----------------------
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))


# Scheduled Tasks  
# -----------------------
