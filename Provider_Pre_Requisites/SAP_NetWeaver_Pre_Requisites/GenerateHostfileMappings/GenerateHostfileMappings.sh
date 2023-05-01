# <copyright file="GenerateHostfileMappings.sh" company="Microsoft Corporation">
# Copyright (c) Microsoft Corporation. All rights reserved.
# </copyright>

#!/bin/bash

# Replace instance number with the instance number of the Central Server instance
instanceNumber=00

# Set the path to the SAP hostctrl executable
cd "/usr/sap/hostctrl/exe"

# Get the hostnames of the SAP system instance
hosts=$(./sapcontrol -prot PIPE -nr $instanceNumber -format script -function GetSystemInstanceList | grep "hostname" | cut -d " " -f 3)

# Get the fully qualified domain name
fqdn=$(./sapcontrol -prot PIPE -nr $instanceNumber -format script -function ParameterValue | grep "SAPFQDN" | cut -d "=" -f 2 | tr -d '\r')

# Declare an array to store the host file entries
hostfile_entries=()

# Loop through each hostname
for hostname in $hosts
do
    ip=$(ping -c 1 $hostname | head -n 1 | cut -d "(" -f 2 | cut -d ")" -f 1)
    hostfile_entries+="$ip $hostname.$fqdn $hostname,"
done

# Print the host file entries separated by commas
hostfile_entries=${hostfile_entries%?}
IFS=","
echo "${hostfile_entries[*]}"