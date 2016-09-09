# This sample script demonstrates the use of two verbs provided for adding
# NPM interfaces:
# o  Orion.NPM.Intefaces.DiscoverInterfacesOnNode
# o  Orion.NPM.Interfaces.AddInterfacesOnNode
#
# Note: These verbs are provided by SWISv3 only.
#
# The script lists all interfaces on a specified node and adds only
# FastEthernet interfaces to monitor.
#
# Please update the hostname and credential setup below to match your
# configuration, as well as the nodeId variable to refer the existing node to use.

# Connect to SWIS
$username = "API_USER"
$password = "ThisIsThePassword!"

# Connect to SWIS with default admin credentials
$target="odc-is-mon01"
$swis = Connect-Swis -host $target -username $username -Password $password

$hostname = "mrc_bd_2960_1.vuhl.root.mrc.local"
# The node ID to discovery interfaces on
$nodeId = (Get-OrionNodeID -NodeName $hostname -SwisConnection $swis)
$nodeid

# Discover interfaces on the node
$discovered = Invoke-SwisVerb $swis Orion.NPM.Interfaces DiscoverInterfacesOnNode $nodeId

if ($discovered.Result -ne "Succeed") {
    Write-Host "Interface discovery failed."
}
else {
    # Uncomment one of the following to limit the interfaces that get added:

    # No. 1: Remove interfaces that are NOT ifType 6 (FastEthernet)
    #$discovered.DiscoveredInterfaces.DiscoveredLiteInterface | ?{ $_.ifType -ne 6 } | %{ $discovered.DiscoveredInterfaces.RemoveChild($_) | Out-Null }

    # No. 2: Remove interfaces that have a caption of 'lo' (Loopback)
    #$discovered.DiscoveredInterfaces.DiscoveredLiteInterface | ?{ $_.Caption.InnerText -eq 'lo' } | %{ $discovered.DiscoveredInterfaces.RemoveChild($_) | Out-Null }

    # Add the remaining interfaces
    #Invoke-SwisVerb $swis Orion.NPM.Interfaces AddInterfacesOnNode @($nodeId, $discovered.DiscoveredInterfaces, "AddDefaultPollers") | Out-Null
    $discovered.DiscoveredInterfaces
}