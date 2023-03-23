instance_number = $0

sudo -u {sidadm} /bin/bash
sudo -u {sidadm} /usr/sap/hostctrl/exe/sapcontrol -nr $instance_number -function ParameterValue service/protectedwebmethods = SDEFAULT -GetQueueStatistic -ABAPGetWPTable -EnqGetStatistic -GetProcessList
sudo -u {sidadm} /usr/sap/hostctrl/exe/sapcontrol -nr $instance_number -function RestartService