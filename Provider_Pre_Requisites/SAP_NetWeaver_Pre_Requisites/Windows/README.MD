# **NetWeaver Provider script to unprotect web methods**

The below steps will set the profile parameter "service/protectedwebmethods" value to "SDEFAULT -GetQueueStatistic -ABAPGetWPTable -EnqGetStatistic -GetProcessList -GetEnvironment" and call the "Restart Service" command to 
apply the change.

1. Login into the central instance SAP windows virtual machine.
2. Save this file in a directory with name e.g : "UnprotectWebmethods.ps1". E.g: C:\Script
3. Open this file in powershell and navigate to the folder C:\Script.
4. Execute the following command in the script directory

.\UnprotectWebmethods.ps1 "<default.pfl file path in computer>" "<sap instance number>"

E.g : .\UnprotectWebmethods.ps1 "H:\usr\sap\SID\SYS\profile\DEFAULT.pfl" "11"

