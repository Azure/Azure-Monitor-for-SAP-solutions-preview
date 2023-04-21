# <copyright file="GenerateHostfileMappings.ps1" company="Microsoft Corporation">
# Copyright (c) Microsoft Corporation. All rights reserved.
# </copyright>

# Instructions:
# 1. Login to the application server using root user credentials.
# 2. Copy this file to the Desktop on the SAP system instance.
# 3. Open powershell in the same directory and run the following command to execute the script:
#    ./GenerateHostfileMappings.ps1 -instanceNumber <instance_number>
# For example: ./GenerateHostfileMappings.ps1 -instanceNumber 00

param(
#[Parameter(Mandatory=$true)]]
[int]$instanceNumber
)

# Set the path to the SAP hostctrl executable
Set-Location -Path "C:\Program Files\SAP\hostctrl\exe"

# Get the hostnames of the SAP system instance
$hosts = .\sapcontrol -prot NI_HTTP -nr $instanceNumber -format script -function GetSystemInstanceList | Select-String -Pattern "hostname" | ForEach-Object {$_.Line.Split()[2]}

# Get the fully qualified domain name
$fqdn = .\sapcontrol -prot NI_HTTP -nr $instanceNumber -format script -function ParameterValue | Select-String -Pattern "SAPFQDN" | ForEach-Object {$_.Line.Split("=")[1]}

$hostfile_entries = New-Object System.Collections.Generic.HashSet[string]

# Loop through each hostnames
foreach ($hostname in $hosts) {
    $ping = Test-Connection -ComputerName $hostname -Count 1
    $ip = $ping.IPV4Address.IPAddressToString
    $hostfile_entries.add("$ip" + " " + "$hostname" + ".$fqdn" + " " + "$hostname")
}

# Print the host file entries
$hostfile_entries -join ", "