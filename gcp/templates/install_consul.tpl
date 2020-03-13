#! /bin/bash

echo "*****    Installing Utils    *****"
sudo apt update
sudo apt install -y unzip ufw jq
sudo ufw enable
sudo ufw allow 8300
sudo ufw allow 8301
sudo ufw allow 8500
sudo ufw allow 8600
sudo ufw allow 22


echo "*****    Download and install Consul on Debian    *****"
cd /tmp
wget https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip
unzip consul_${consul_version}_linux_amd64.zip
sudo mv consul /usr/local/bin/
consul -v

echo "*****    gcloud login and get join addrs    *****"
sudo echo '${credentials}' > /var/gcp_key.json
gcloud auth activate-service-account --key-file=/var/gcp_key.json --project=${gcp_project}
JOIN_ADDRS=$(gcloud compute instances list -r "consul-.*" --format=json | jq .[].networkInterfaces[0].networkIP | tr '\n' ',' | head -c-1)
MY_ADDR=$(gcloud compute instances list -r "`hostname`" --format=json | jq --raw-output .[].networkInterfaces[0].networkIP)
echo $JOIN_ADDRS

echo "*****    Download and install Consul on Debian    *****"
sudo groupadd --system consul
sudo useradd -s /sbin/nologin --system -g consul consul

sudo mkdir -p /var/lib/consul
sudo chown -R consul:consul /var/lib/consul
sudo chmod -R 775 /var/lib/consul

sudo mkdir /etc/consul.d
sudo chown -R consul:consul /etc/consul.d

echo "*****    Bootstrap Consul    *****"
sudo cat > /etc/consul.d/config.json << EOF
{
    "advertise_addr": "$MY_ADDR",
    "bind_addr": "$MY_ADDR",
    "bootstrap_expect": 3,
    "client_addr": "0.0.0.0",
    "datacenter": "${datacenter}",
    "data_dir": "/var/lib/consul",
    "domain": "consul",
    "enable_script_checks": true,
    "dns_config": {
        "enable_truncate": true,
        "only_passing": true
    },
    "enable_syslog": true,
    "encrypt": "${encrypt}",
    "leave_on_terminate": true,
    "log_level": "INFO",
    "rejoin_after_leave": true,
    "retry_join": [$JOIN_ADDRS],
    "server": true,
    "start_join": [$JOIN_ADDRS],
    "ui": true
}
EOF

echo "*****    Run Consul    *****"
sudo ${excute}