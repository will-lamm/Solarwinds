# This sample script demonstrates how to set a custom property of a node
# or an interface using CRUD operations.
#
# Please update the hostname and credential setup to match your configuration, and
# reference to an existing node and interface which custom property you want to set.



#Needed Info

$nodename
$location
$owners = (Get-SwisData -SwisConnection $swis -Query "SELECT Name FROM Orion.NodesCustomProperties" |select -unique| sort $_.DisplayName)


function Add-SWProperties{ 
    Param($hostname,
    [ValidateSet("KDC","ODC")][STRING]$location)


# Connect to SWIS
$target = "lkc-mon-01"
$username = "API_User"
$password = "ThisIsThePassword!"
#$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist {"API_User",$password}

$swis = Connect-Swis -host $target -UserName $username -Password $password

$nodeId = (Get-OrionNodeID -NodeName $hostname -SwisConnection $swis) # NodeID of a node which custom properties you want to change
#$ifaceId = 58 # InterfaceID of an interface on the node

    If($location = "KDC"){
        $address = "1102 Grand Blvd"
        $city = "Kansas City, MO 64106"
    }
    ElseIf($location = "ODC"){
        $address = "17775 106TH ST"
        $city = "Olathe, KS 66061"
    }
# prepare a custom property value
$owners = (Get-SwisData -SwisConnection $swis -Query "SELECT Name FROM Orion.NodesCustomProperties" |select -unique| sort $_.DisplayName)
$customProps = @{
    Address = $Address                                                                                                              
    Alerting = ""                                                                                                            
    #AOScloud_Coverage                                                                                                     
    #AssetTag                                                                                                              
    Business_Owner = Select-TextItem $owners                                                                                                  
    City = $city                                                                                                             
    #Comments                                                                                                              
    #Department                                                                                                            
    #Disaster_Recovery                                                                                                     
    #Imported_From_NCM                                                                                                     
    InServiceDate = (Get-Date)                                                                                                         
    #Last_Change                                                                                                           
    Machine_Type = "Servers - Windows"                                                                                                        
    #Network_Provider                                                                                                      
    #Network_Provider_Support_Phone                                                                                        
    Node_Purpose = (Read-host "Node Purpose")                                                                                                        
    Owner = (Read-host "Owner")                                                                                                                   
    #PONumber                                                                                                              
    #Purchase_Cost                                                                                                         
    #Purchased_From                                                                                                        
    #PurchaseDate                                                                                                          
    #PurchasePrice                                                                                                         
    #DisplayName                                                                                                           
    #Description                                                                                                           
    #InstanceType                                                                               Orion.NodesCustomProperties
    #Uri                            swis://mrc-cp-prtg01.vuhl.root.mrc.local/Orion/Orion.Nodes/NodeID=1992/CustomProperties
    #InstanceSiteId    
}

# build the node URI
$uri = "swis://localhost/Orion/Orion.Nodes/NodeID=$($nodeId)/CustomProperties";

# set the custom property
Set-SwisObject $swis -Uri $uri -Properties $customProps

# build the interface URI
#$uri = "swis://localhost/Orion/Orion.Nodes/NodeID=$($nodeId)/Interfaces/InterfaceID=$($ifaceId)/CustomProperties";

# set the custom property
#Set-SwisObject $swis -Uri $uri -Properties $customProps
}

