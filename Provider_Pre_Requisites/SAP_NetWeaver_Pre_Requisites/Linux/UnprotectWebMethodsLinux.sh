# <copyright file="UnprotectWebMethodsLinux.sh" company="Microsoft Corporation">
# Copyright (c) Microsoft Corporation. All rights reserved.
# </copyright>

#!/bin/bash

# Replace instance number with the instance number of the Central Server instance
instanceNumber=00
# replace siadam with the SIDADM user of the SAP System
siadam=l13adm

# update the parameter value and restart the service
sudo -u $siadam /usr/sap/hostctrl/exe/sapcontrol -nr $instanceNumber -function ParameterValue service/protectedwebmethods = SDEFAULT -GetQueueStatistic -ABAPGetWPTable -EnqGetStatistic -GetProcessList -GetEnvironment
sudo -u $siadam /usr/sap/hostctrl/exe/sapcontrol -nr $instanceNumber -function RestartService

echo "Parameter service/protectedwebmethods updated successfully"