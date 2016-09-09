# This sample script demonstrates how to add a new node using CRUD operations and add WMI Polling.
# Please update the hostname and credential setup to match your configuration, and
# information about the node you would like to add for monitoring.

#Region PSSnapin presence check/add
if (-not (Get-PSSnapin -Name "SwisSnapin" -ErrorAction SilentlyContinue))
{    
    Add-PSSnapin SwisSnapin -ErrorAction SilentlyContinue
}
#EndRegion

#Clear-Host

function AddPoller($PollerType) {
    $poller["PollerType"] = $PollerType
    $pollerUri = New-SwisObject $swis -EntityType "Orion.Pollers" -Properties $poller
}

$username = "API_USER"
$password = "ThisIsThePassword!"
#$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist {$username, $password}

# Connect to SWIS with default admin credentials
$target="lkc-mon-01"
$swis = Connect-Swis -host $target -username $username -Password $password
$ip = "10.223.47.20"
$credentialName = "Solarwinds Windows Service Account" # Enter here the name under which the WMI credentials are stored. You can find it in the "Manage Windows Credentials" section of the Orion website (Settings)

# Node properties
$newNodeProps = @{
    IPAddress = $ip
    EngineID = 3
    ObjectSubType = "WMI"
    SysName = "uat-ss-glbmtx1"
    #DisplayName = "uat-ss-glbmtx1"
    NodeName = "uat-ss-glbmtx1"
    DNS = "uat-ss-glbmtx1"
    DynamicIP = "True"
    MachineType = "Server"
    IsServer = "True"

}

#Creating the node
$newNodeUri = New-SwisObject $swis -EntityType "Orion.Nodes" -Properties $newNodeProps
$nodeProps = Get-SwisObject $swis -Uri $newNodeUri

#Getting the Credential ID
$credentialId = Get-SwisData $swis "SELECT ID FROM Orion.Credential where Name = '$credentialName'"
if (!$credentialId) {
	Throw "Can't find the Credential with the provided Credential name '$credentialName'."
}

#Adding NodeSettings
$nodeSettings = @{
    NodeID = $nodeProps["NodeID"]
    SettingName = "WMICredential"
    SettingValue = ($credentialId.ToString())
}

#Creating node settings
$newNodeSettings = New-SwisObject $swis -EntityType "Orion.NodeSettings" -Properties $nodeSettings

# register specific pollers for the node
$poller = @{
    NetObject = "N:" + $nodeProps["NodeID"]
    NetObjectType = "N"
    NetObjectID = $nodeProps["NodeID"]
}

#Status
AddPoller("N.Status.ICMP.Native")

#ResponseTime
AddPoller("N.ResponseTime.ICMP.Native")

#Details
AddPoller("N.Details.WMI.Vista")

#Uptime
AddPoller("N.Uptime.WMI.XP")

#CPU
AddPoller("N.Cpu.WMI.Windows")

#Memory
AddPoller("N.Memory.WMI.Windows")