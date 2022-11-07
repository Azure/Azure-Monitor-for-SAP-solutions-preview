param(
    [Parameter(Mandatory=$true)]
    [string]$ArmId,
    [Parameter(Mandatory=$true)]
    [String[]] $subscriptions
)

# Install module pre-requisites
<#
.SYNOPSIS
Function to Install azure module pre-requisites

.EXAMPLE
InstallModules
#>
function InstallModules()
{
    try {
        $m = Get-InstalledModule Az -MinimumVersion 5.1.0 -ErrorAction "Stop"
    }
    catch {
    }
    if ($null -eq $m)
    {
        Write-Host -ForegroundColor Green "Installing Az Module."
        Install-Module Az -AllowClobber
        Write-Host -ForegroundColor Green "Installed Az Module."
    }
    else {
        Import-Module Az
        Write-Host -ForegroundColor Green "Importing installed Az Module."
    }

    $m = $null
    try {
        $m = Get-InstalledModule AzureAD -MinimumVersion 2.0.2.61 -ErrorAction "Stop"
    }
    catch {
    }
    if ($null -eq $m)
    {
        Write-Host -ForegroundColor Green "Installing AzureAD Module."
        Install-Module AzureAD
        Write-Host -ForegroundColor Green "Installed AzureAD Module."
    }
    else {
        Import-Module AzureAD
    }
}

## Function to Parse the ARM Id given by the user.
function Get-ParsedArmId($armId)
{
    $CharArray =$armId.Split("/")
    $i=2

    $parsedInput = @{
        subscriptionId = $CharArray[$i]
        amsResourceGroup = $CharArray[$i+2]
        amsResourceName = $CharArray[$CharArray.Length-1]
    }

    return $parsedInput
}

## Function to fetch the Managed Resource Group for the AMS.
function GetAmsV2MonitorProperties([string]$subscriptionId, [string]$resourceGroup, [string]$monitorName)
{
    $rawToken = Get-AzAccessToken -ResourceTypeName Arm;
    $armToken = $rawToken.Token;
	$v2ApiVersion = "2021-12-01-preview";

    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $armToken"
    }

    [string]$url = "https://management.azure.com/";
	[string]$subscriptionParams = "subscriptions/" + $subscriptionId;
	[string]$rgParams = "/resourceGroups/" + $resourceGroup;
	[string]$providerParams = "/providers/Microsoft.Workloads/monitors/" + $monitorName + "?api-version=" + $v2ApiVersion;
	$url = $url + $subscriptionParams + $rgParams + $providerParams;
	[string]$provisiongState = "";
    
	try
    {
        $response = Invoke-RestMethod -Method 'get' -Uri $url -Headers $headers;
		$mrgName = $response.properties.managedResourceGroupConfiguration.name;
    }
    catch
    {
        $GetProviderErrorMsg = $_.ErrorDetails.ToString();
		Write-Output "GetAmsV2MonitorProperties : ($($GetProviderErrorMsg.error.code)))";
		$managedResourceGroup = "";
    }

	return $mrgName
}

Write-Output "Checking and Installing Required Modules.."
InstallModules

Write-Output "Parsing ArmId"
$ArmDetails = Get-ParsedArmId -armId $ArmId

Write-Output $AmsArmDetails
$subcriptionArmId = "/subscriptions/" + $ArmDetails.subscriptionId

$mrg = GetAmsV2MonitorProperties -subscriptionId $ArmDetails.subscriptionId -resourceGroup $ArmDetails.amsResourceGroup -monitorName $ArmDetails.amsResourceName
Write-Output "Managed Resource Group name is : $mrg" 

Write-Output "Fetching Managed Identity Details in Resource Group $mrg"
$managedIdentityList = Get-AzResource -ResourceGroupName $mrg -Name "$providerType*" -ResourceType Microsoft.ManagedIdentity/userAssignedIdentities -ErrorAction Stop

$managedIdentityDetails = Get-AzADServicePrincipal -SearchString $managedIdentityList[0].Name
    (Get-AzADServicePrincipal -DisplayName $managedIdentityList[0].Name).id

Write-Output "Assigning Reader Role Permission to Managed Identity for Subscription $subcriptionArmId."
New-AzRoleAssignment -ObjectId $managedIdentityDetails.Id -RoleDefinitionName "Reader" -Scope $subcriptionArmId # -ErrorAction Stop

foreach ($subcriptionId in $subscriptions)
{
    $subcriptionArmId = "/subscriptions/" + $subcriptionId
    Write-Output "Assigning Reader Role Permission to Managed Identity for Subscription $subcriptionArmId."
    New-AzRoleAssignment -ObjectId $managedIdentityDetails.Id -RoleDefinitionName "Reader" -Scope $subcriptionArmId # -ErrorAction Stop
}
