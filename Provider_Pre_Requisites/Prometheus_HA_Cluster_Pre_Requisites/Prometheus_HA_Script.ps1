param(
#[Parameter(Mandatory=$true)]
$vmDetails = "virtual_machine1",

#[Parameter(Mandatory=$true)]
$subscriptionId = "subscription-guid",

#[Parameter(Mandatory=$true)]
$resourceGroup = "resource-group-name"
)

Get-AzContext

# Get the current universal time in the default string format.
$startDate = (Get-Date).ToUniversalTime()


Set-AzContext -SubscriptionId $subscriptionId
$scriptPath = "install_ha_cluster_exporter.sh"

foreach ($vmName in $vmDetails)
{
    Write-Host "Running commands from $scriptPath on $vmName at $startDate"
    Write-Host "It might take 3 to 4 minutes to execute."
    Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -Name $vmName -CommandId 'RunShellScript' -ScriptPath $scriptPath
    Write-Host "Script executed successfully"
}