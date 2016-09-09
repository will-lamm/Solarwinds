# This sample script demonstrates how to add a new node using CRUD operations and add WMI Polling.
# Please update the hostname and credential setup to match your configuration, and
# information about the node you would like to add for monitoring.

Function Add-SWNode{ 
    Param(
        [Parameter(Mandatory=$true)][string]$hostname,
        [ValidateSet("KDC","ODC")][STRING]$location)

Import-Module powerorion

if (-not (Get-PSSnapin -Name "SwisSnapin" -ErrorAction SilentlyContinue))
{    
    Add-PSSnapin SwisSnapin -ErrorAction SilentlyContinue
}

$username = "API_USER"
$password = "ThisIsThePassword!"
#$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist {$username, $password}

# Connect to SWIS with default admin credentials
$target="lkc-mon-01"
$swis = Connect-Swis -host $target -username $username -Password $password
#Region PSSnapin presence check/add

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
#$ip = "10.223.47.20"
$credentialName = "Solarwinds Windows Service Account" # Enter here the name under which the WMI credentials are stored. You can find it in the "Manage Windows Credentials" section of the Orion website (Settings)
Try{
    $IP = [system.net.dns]::Gethostaddresses($hostname).ipaddresstostring
    }
    catch{
    Write-host "$hostname Won't Resolve." 
    Break
    }
# Node properties
$newNodeProps = @{
    IPAddress = $IP
    EngineID = 3
    ObjectSubType = "WMI"
    SysName = $hostname
    NodeName = $hostname
    DNS = $hostname
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

#Volume
AddPoller("V.Details.WMI.Windows");

#Statistics
AddPoller("V.Statistics.WMI.Windows");

#testing block
}
Add-SWNode -hostname "dev-is-willtst1" -location KDC


Add-SWProperties -hostname $hostname -location $location

Add-SWTemplate -hostname $hostname
<#
$username = "API_USER"
$password = "ThisIsThePassword!"
#$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist {$username, $password}

# Connect to SWIS with default admin credentials
$target="lkc-mon-01"
$swis = Connect-Swis -host $target -username $username -Password $password

$alerting = (Get-SwisData -SwisConnection $swis -Query "SELECT Alerting FROM Orion.NodesCustomProperties" |select -unique| sort $_.DisplayName)
$owners = (Get-SwisData -SwisConnection $swis -Query "SELECT Business_Owner FROM Orion.NodesCustomProperties" |select -unique| sort $_.DisplayName)
$nodeId = (Get-OrionNodeID -NodeName $hostname -SwisConnection $swis) # NodeID of a node which custom properties you want to change
If($nodeid.Length -ne 1){
    write-host "Duplicate hostname!"
    pause
    exit
}
#$ifaceId = 58 # InterfaceID of an interface on the node

    If($location = "KDC"){
        $address = "1102 Grand Blvd"
        $city = "Kansas City, MO 64106"
    }
    ElseIf($location = "ODC"){
        $address = "17775 106TH ST"
        $city = "Olathe, KS 66061"
    }
$date = (Get-Date).ToString()
Add-Type -AssemblyName Microsoft.VisualBasic
$owner = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Owner", "Owner", "$env:Owner")
$purpose = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Node Purpose", "Purpose", "$env:Purpose") 
# prepare a custom property value
$customProps = @{
    Address = $Address                                                                                                              
    Alerting = (Select-TextItem $alerting)                                                                                                            
    #AOScloud_Coverage                                                                                                     
    #AssetTag                                                                                                              
    Business_Owner = (Select-TextItem $owners)
    City = $city                                                                                                             
    #Comments                                                                                                              
    #Department                                                                                                            
    #Disaster_Recovery                                                                                                     
    #Imported_From_NCM                                                                                                   
    InServiceDate = $date                                                                                                        
    #Last_Change                                                                                                           
    Machine_Type = "Servers - Windows"                                                                                                        
    #Network_Provider                                                                                                      
    #Network_Provider_Support_Phone                                                                                       
    Node_Purpose = $purpose 
    Owner = $owner                                                                                                                 
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
$uri = "swis://localhost/Orion/Orion.Nodes/NodeID=$($nodeId[-1])/CustomProperties";

# set the custom property
$customProps
Set-SwisObject $swis -Uri $uri -Properties $customProps

# build the interface URI
#$uri = "swis://localhost/Orion/Orion.Nodes/NodeID=$($nodeId)/Interfaces/InterfaceID=$($ifaceId)/CustomProperties";

# set the custom property
#Set-SwisObject $swis -Uri $uri -Properties $customProps#>
}#END FUNCTION


# This sample script demonstrates how to set a custom property of a node
# or an interface using CRUD operations.
#
# Please update the hostname and credential setup to match your configuration, and
# reference to an existing node and interface which custom property you want to set.




function Add-SWProperties{ 
    Param($hostname,
    [ValidateSet("KDC","ODC")][STRING]$location)


$username = "API_USER"
$password = "ThisIsThePassword!"
#$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist {$username, $password}

# Connect to SWIS with default admin credentials
$target="lkc-mon-01"
$swis = Connect-Swis -host $target -username $username -Password $password

$alerting = (Get-SwisData -SwisConnection $swis -Query "SELECT Alerting FROM Orion.NodesCustomProperties" |select -unique| sort $_.DisplayName)
$owners = (Get-SwisData -SwisConnection $swis -Query "SELECT Business_Owner FROM Orion.NodesCustomProperties" |select -unique| sort $_.DisplayName)
$nodeId = (Get-OrionNodeID -NodeName $hostname -SwisConnection $swis) # NodeID of a node which custom properties you want to change
If($nodeid.Length -ne 1){
    write-host "Duplicate hostname!"
    pause
    exit
}
#$ifaceId = 58 # InterfaceID of an interface on the node

    If($location = "KDC"){
        $address = "1102 Grand Blvd"
        $city = "Kansas City, MO 64106"
    }
    ElseIf($location = "ODC"){
        $address = "17775 106TH ST"
        $city = "Olathe, KS 66061"
    }
$date = (Get-Date).ToString()
Add-Type -AssemblyName Microsoft.VisualBasic
$owner = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Owner", "Owner", "$env:Owner")
$purpose = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Node Purpose", "Purpose", "$env:Purpose") 

# prepare a custom property value
$customProps = @{
    Address = $Address                                                                                                              
    Alerting = (Select-Item $alerting)                                                                                                            
    #AOScloud_Coverage                                                                                                     
    #AssetTag                                                                                                              
    Business_Owner = (Select-Item $owners)
    City = $city                                                                                                             
    #Comments                                                                                                              
    #Department                                                                                                            
    #Disaster_Recovery                                                                                                     
    #Imported_From_NCM                                                                                                   
    InServiceDate = $date                                                                                                        
    #Last_Change                                                                                                           
    Machine_Type = "Servers - Windows"                                                                                                        
    #Network_Provider                                                                                                      
    #Network_Provider_Support_Phone                                                                                       
    Node_Purpose = $purpose 
    Owner = $owner                                                                                                                 
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
$uri = "swis://localhost/Orion/Orion.Nodes/NodeID=$($nodeId[-1])/CustomProperties";

# set the custom property
Set-SwisObject $swis -Uri $uri -Properties $customProps

# build the interface URI
#$uri = "swis://localhost/Orion/Orion.Nodes/NodeID=$($nodeId)/Interfaces/InterfaceID=$($ifaceId)/CustomProperties";

# set the custom property
#Set-SwisObject $swis -Uri $uri -Properties $customProps
}

function Select-TextItem 
{ 
PARAM  
( 
    [Parameter(Mandatory=$true)] 
    $options, 
    $displayProperty 
) 
 
    [int]$optionPrefix = 1 
    # Create menu list 
    foreach ($option in $options) 
    { 
        if ($displayProperty -eq $null) 
        { 
            Write-Host ("{0,3}: {1}" -f $optionPrefix,$option) 
        } 
        else 
        { 
            Write-Host ("{0,3}: {1}" -f $optionPrefix,$option.$displayProperty) 
        } 
        $optionPrefix++ 
    } 
    Write-Host ("{0,3}: {1}" -f 0,"To cancel")  
    [int]$response = Read-Host "Enter Selection" 
    $val = $null 
    if ($response -gt 0 -and $response -le $options.Count) 
    { 
        $val = $options[$response-1] 
    } 
    return $val 
}


# This sample script demonstrates the use of verbs provided for manipulating
# applications and templates. The verbs are defined by "Orion.APM.Application"
# and "Orion.APM.ApplicationTemplate" entity types.
#
# The script progresses in several steps:
# 1. Creating a new application by assigning a template to a node.
# 2. Executing "Poll Now" on an application
# 3. Unmanage an application
# 4. Remanage an application
# 5. Deleting an application
# 6. Deleting an application template (commented out from the script execution)
#
# Please update the hostname and credential setup to match your configuration.

<#
$target = "lkc-mon-01"
$username = "API_User"
$password = "ThisIsThePassword!"
#$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
$swis = Connect-Swis -host $target -username $username -Password $password#>

Function Add-SWTemplate{ 
    Param([parameter(mandatory=$true)][string]$hostname)

#Incoming stuff needed
if (-not (Get-PSSnapin "SwisSnapin")) {
    Add-PSSnapin "SwisSnapin"
}

# Connect to SWIS
$target = "lkc-mon-01"
$username = "API_User"
$password = "ThisIsThePassword!"
#$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
$swis = Connect-Swis -host $target -username $username -Password $password

#
# ASSIGNING TEMPLATE TO A NODE
#
# Select the node, application template, and credential set, and create the application by the assigning template to node
# with the selected credential set.
#

# Select the node
$nodeId = (Get-OrionNodeID -NodeName $hostname -SwisConnection $swis)
if (!$nodeId) {
	Write-Host "Can't find node with name $hostname."
	exit
}
If($nodeid.Length -ne 1){
    write-host "Duplicate hostname!"
    exit
}
#$nodeId = Get-SwisData $swis "SELECT NodeID FROM Orion.Nodes WHERE IP_Address=@ip" @{ ip = $ip }


# Select the template
$appid = 63,368,389
$values = @()
foreach($num in $appid){
    $values += (Get-SwisData -SwisConnection $swis -Query "SELECT Name FROM Orion.APM.Application WHERE ApplicationTemplateID=@applicationtemplateid" @{ applicationtemplateid = $num}|select -Unique)
    }
#$values
$templates = Select-Item $values
Foreach($template in $templates){
    $applicationTemplateId = Get-SwisData $swis "SELECT ApplicationTemplateID FROM Orion.APM.ApplicationTemplate WHERE Name=@template" @{ template = $template }
    #Get-SwisData $swis "SELECT customapplicationtype FROM Orion.APM.ApplicationTemplate" | select -Unique | sort $_.displayname

    if (!$applicationTemplateId) {
	    Write-Host "Can't find template with name '$template'."
	    exit
    }

    # Select the credential
    $credential = "Solar Services Account"
    $credentialSetId = Get-SwisData $swis "SELECT ID FROM Orion.Credential WHERE CredentialOwner='APM' AND Name=@credential" @{ credential = $credential }

    if (!$credentialSetId) {
	    Write-Host "Can't find credential with name '$credential'."
	    exit
    }

    # Credentials from the SAM credential library are expected to have credentialSetId > 0.
    # But the "CreateApplication" method accepts the following special IDs for credentials:
    #
    # <None>
    #    $credentialSetId = 0 
    #
    # <Inherit Windows credential from node> (should be used only for WMI nodes)
    #    $credentialSetId = -3
    #
    # <Inherit credentials from template>
    #    $credentialSetId = -4

    Write-Host "Creating application on node '$nodeId' using template '$applicationTemplateId' and credential '$credentialSetId'."

    # Assign the application template to a node to create the application
    $applicationId = (Invoke-SwisVerb $swis "Orion.APM.Application" "CreateApplication" @(
        # Node ID
        $nodeId,
    
	    # Application Template ID
        $applicationTemplateId,
    
	    # Credential Set ID
        $credentialSetId,
	
	    # Skip if duplicate (in lowercase)
        "true"
    )).InnerText

    # Check if the application was created
    if ($applicationId -eq -1) {
	    Write-Host "Application wasn't created. Likely the template is already assigned to node and the skipping of duplications are set to 'true'."
	    exit
    }
    else {
	    Write-Host "Application created with ID '$applicationId'."
    }
}
}

function Select-Item 
{ 
PARAM  
( 
    [Parameter(Mandatory=$true)] 
    $options, 
    [Parameter(Mandatory=$false)] 
    $displayProperty 
) 

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form 
$form.Text = "Data Entry Form"
$form.Size = New-Object System.Drawing.Size(400,600) 
$form.StartPosition = "CenterScreen"

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75,520)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)|out-null

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150,520)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)|out-null

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20) 
$label.Size = New-Object System.Drawing.Size(380,20) 
$label.Text = "Please make a selection from the list below:"
$form.Controls.Add($label) |out-null

$listBox = New-Object System.Windows.Forms.Listbox 
$listBox.Location = New-Object System.Drawing.Point(10,40) 
$listBox.Size = New-Object System.Drawing.Size(360,420) 

$listBox.SelectionMode = "MultiExtended"

 #Populate ListBox 
    foreach ($option in $options) 
    { 
        $listBox.Items.Add($option)|out-null
    } 

$listBox.Height = 470
$form.Controls.Add($listBox)|out-null 
$form.Topmost = $True

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $listBox.SelectedItems
    return $x
}
}
 




