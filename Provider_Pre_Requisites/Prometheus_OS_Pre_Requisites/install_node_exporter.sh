# Downloading and setting up node exported.
# You can check the latest version of the node exporter by using the below link and update the references in the script.
# https://github.com/prometheus/node_exporter/releases

echo "Downloading node exporter 1.3.1"
wget 'https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz' -O node_exporter-1.3.1.linux-amd64.tar.gz 

echo "Starting to unzip node exporter file"
tar -zxvf node_exporter-1.3.1.linux-amd64.tar.gz

if [[ "$(grep '^ID=' /etc/*-release)" == *"rhel"* ]]; then
    echo "Open firewall port 9100 on the Linux host"
    sudo apt install firewalld -y
    systemctl start firewalld
    firewall-cmd --zone=public --permanent --add-port 9100/tcp
else
    sudo ufw allow 9100/tcp
    sudo ufw reload
fi

echo "Start listening on port 9100"
cd node_exporter-1.3.1.linux-amd64 && nohup ./node_exporter --web.listen-address=":9100" &