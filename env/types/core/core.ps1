#
# core server setup 
#

# Variables
# -----------------------
$env:TestVariable = "This is a test environment variable."

# Ports
# -----------------------
New-NetFirewallRule -DisplayName 'HTTP(S) Inbound' -Profile @('Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('80', '443')

# Users  
# -----------------------
New-LocalUser -Name "LocalSys" -Description "director account" -NoPassword
Add-LocalGroupMember -Group "Administrators" -Member "LocalSys"

# Install Package Software
# -----------------------
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))


# Scheduled Tasks  
# -----------------------
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
  -Argument '-NoProfile -WindowStyle Hidden -command "& {get-eventlog -logname Application -After ((get-date).AddDays(-1)) | Export-Csv -Path c:\fso\applog.csv -Force -NoTypeInformation}"'
$trigger =  New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "AppLog" -Description "Daily dump of Applog"s