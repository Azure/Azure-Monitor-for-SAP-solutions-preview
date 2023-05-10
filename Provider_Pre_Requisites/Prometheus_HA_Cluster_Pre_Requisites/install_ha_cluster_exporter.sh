sysctl vm.drop_caches=3
systemctl restart purge-kernels.service
echo "$(grep '^ID=' /etc/*-release)"
# ID is "rhel" or "sles" based on redhat/suse

if [[ "$(grep '^ID=' /etc/*-release)" == *"rhel"* ]]; then
    echo "Running yum install command for RHEL"
    yum install pcp pcp-pmda-hacluster -y
    echo "Enable and start the required PCP Collector Services."
    systemctl enable pmcd
    systemctl start pmcd
    cd /var/lib/pcp/pmdas/hacluster
    ./Install
    echo "Enable and start the pmproxy service."
    systemctl start pmproxy
    systemctl enable pmproxy
    echo "you can check the metrics on http://<IP-Address>:44322/metrics"
else
    echo "Running zypper install command"
    sudo zypper install prometheus-ha_cluster_exporter -y
    echo "starting ha cluster exporter"
    ha_cluster_exporter
    echo "you can check the metrics on http://<IP-Address>:9664/metrics"
fi
echo "Manual commands execution Completed"
