# <copyright file="GenerateHostfileMappings.sh" company="Microsoft Corporation">
# Copyright (c) Microsoft Corporation. All rights reserved.
# </copyright>

# Instructions:
# 1. Login to the application server using root user credentials.
# 2. Copy this file to the home directory on the SAP system instance.
# 3. Run the following command to execute the script: ./GenerateHostfileMappings.sh <instance_number>
# For example: ./GenerateHostfileMappings.sh 00


#!/bin/bash
# Get instance number as a parameter
instanceNumber=$1

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
    hostfile_entries+="$ip $hostname.$fqdn $hostname, "
done

# Print the host file entries separated by commas
IFS=","
echo "${hostfile_entries[*]}"