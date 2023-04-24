## Generate hostfile mappings input for NetWeaver Provider in AMS

### Windows Virtual Machines

Steps:

1. Login to the application server using root user credentials.
2. Copy the "GenerateHostfileMappings.ps1" file to the Desktop on the SAP system instance.
3. Open powershell in the same directory and run the following command to execute the script:
```./GenerateHostfileMappings.ps1 -instanceNumber <instance_number>```
For example: ./GenerateHostfileMappings.ps1 -instanceNumber 00

### Windows Virtual Machines

Steps:

1. Login to the application server using root user credentials.
2. Copy the "GenerateHostfileMappings.sh" file to the home directory on the SAP system instance.
3. Run the following command to execute the script: 
```./GenerateHostfileMappings.sh <instance_number>```
For example: ./GenerateHostfileMappings.sh 00