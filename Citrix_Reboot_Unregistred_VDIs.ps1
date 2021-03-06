#########################################################################################
##                                                                                      #
## Based upon sample code from the following Citrix blog articles                       #
## http://blogs.citrix.com/2012/12/05/xendesktop-powershell-sdk-script-examples-part-1/ #
## http://blogs.citrix.com/2012/10/27/xendesktop-monitoring-desktop-availability/       #
##                                                                                      #
## This script will connect to your XenDesktop environment and provide a list of        #
## desktop(s) that are powered on, but unregistered or it will perform a forced restart #
## on the VM(s).  To modify this behavior just uncomment the appropriate line.          #
##                                                                                      #
## Finally the script will send an email with a listing of all restarted desktops.      #
##                                                                                      #
## Pre-reqs: Powershell, Citrix DDC SDK                                                 #
##                                                                                      #
## Use of this script is at your own risk, not responsible for data loss/corruption or  #
## dragons invading your data center.                                                   #
##                                                                                      #
## Michael Davis - 01/09/13                                                             #
##                                                                                      #
#########################################################################################

##Load Citrix Modules
asnp Citrix.*

#Variables for email
[string[]]$recipients = "recipient@domain.com"
$fromEmail = "sender@domain.com"
$server = "emailserver.domain.com"
$date= Get-Date

##Check for VMs on and unregistered
$unregisteredVMs = (Get-BrokerDesktop -MaxRecordCount 5000 | ? {($_.PowerState -eq 'On') -and ($_.RegistrationState -eq 'Unregistered')} | select MachineName)
[string]$emailVMs = (Get-BrokerDesktop -MaxRecordCount 5000 | ? {($_.PowerState -eq 'On') -and ($_.RegistrationState -eq 'Unregistered')} | select HostedMachineName | ft -wrap -autosize | Out-String)

IF (!$unregisteredVMs) {
##Send all clear email
[string]$emailBody = "There were no powered on desktops in an unregistered state."
send-mailmessage -from $fromEmail -to $recipients -subject " XenDesktop Daily Check - $date" -body $emailBody -priority High -smtpServer $server
}
Else {
##If powered-on and unregistered, perform a forceful restart
foreach ($unregisteredVM in $unregisteredVMs)
{
 New-BrokerHostingPowerAction -MachineName $unregisteredVM.MachineName -Action Reset
 #Write-Host "Hello, I am unregistered: $unregisteredVM"
}
 
#Send an email report of VMs to be restarted due to being in an unregistered state
[string]$emailBody = "The following desktops were forcefully restarted due to not registering with the DDCs in a timely manner. `n $emailVMs"
send-mailmessage -from $fromEmail -to $recipients -subject " XenDesktop Daily Check - $date" -body $emailBody -priority High -smtpServer $server
}