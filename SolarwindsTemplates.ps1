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
if (-not (Get-PSSnapin "SwisSnapin")) {
    Add-PSSnapin "SwisSnapin"
}

$target = "lkc-mon-01"
$username = "API_User"
$password = "ThisIsThePassword!"
#$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
$swis = Connect-Swis -host $target -username $username -Password $password

Function Add-SWTemplate{ 
    Param([parameter(mandatory=$true)][string]$hostname)

#Incoming stuff needed


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

#$values = (Get-SwisData -SwisConnection $swis -Query "SELECT Name FROM Orion.APM.Application"|select -Unique |sort $_)
#$templates = Select-Item $values

#Add-SWTemplate -hostname "dev-is-willtst1"

<#
# EXECUTING "POLL NOW"
#
# Execute "Poll Now" on created application.
#
Write-Host "Executing Poll Now for application '$applicationId'."
Invoke-SwisVerb $swis "Orion.APM.Application" "PollNow" @($applicationId) | Out-Null
Write-Host "Poll Now for application '$applicationId' was executed."

#
# UNMANAGING APPLICATION
#
# Unmanaging created application.
#
Write-Host "Unmanaging application '$applicationId'."

$applicationNetObjectId = "AA:$applicationId"
$unmanageTime = Get-Date
$remanageTimeRelative = Get-Date -Date "1970-01-01 00:04:00"

Invoke-SwisVerb $swis "Orion.APM.Application" "Unmanage" @(
    # NetObjectID - for application has format "AA:<ApplicationID>"
	$applicationNetObjectId,
	
	# Unmanage time
	$unmanageTime,
	
	# Remanage time
	$remanageTimeRelative,
	
	# If the remanage time is relative (in lowercase). If "true" then the time of the day (hours, minutes and second)
	# is used for the calculation of remanage time.
	"true"
) | Out-Null

Write-Host "Application '$applicationId' is unmanaged."

#
# REMANAGING APPLICATION
#
# Remanaging created application.
#
Write-Host "Remanaging application '$applicationId'."
Invoke-SwisVerb $swis "Orion.APM.Application" "Remanage" @($applicationNetObjectId) | Out-Null
Write-Host "Application '$applicationId' is remanaged."

#
# DELETING APPLICATION
#
# Delete the created application.
#
Write-Host "Deleting application '$applicationId'."
Invoke-SwisVerb $swis "Orion.APM.Application" "DeleteApplication" @($applicationId) | Out-Null
Write-Host "Application '$applicationId' was deleted."

#
# DELETING APPLICATION TEMPLATE
#
# Delete the application template. Removing the template also removes all applications created from this template.
#
# Change the application template ID here
#$applicationTemplateId = 0
#Invoke-SwisVerb $swis "Orion.APM.ApplicationTemplate" "DeleteTemplate" @($applicationTemplateId) | Out-Null
#Write-Host "Application template '$applicationTemplateId' was deleted."

#>

