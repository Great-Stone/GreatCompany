#! /bin/bash

echo "*****    Installing Utils    *****"
sudo apt update
sudo apt install -y unzip ufw jq apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable"
sudo apt update
sudo apt -y install docker-ce


sudo apt autoremove -y

sudo ufw enable
sudo ufw allow 8300 # consule
sudo ufw allow 8301 # consule
sudo ufw allow 8302 # consule
sudo ufw allow 8500 # consule
sudo ufw allow 8600 # consule
sudo ufw allow 4646 # nomad
sudo ufw allow 4647 # nomad
sudo ufw allow 4648 # nomad

sudo ufw allow 1936 # haproxy
sudo ufw allow 8080 # haproxy

sudo ufw allow 22


echo "*****    Download and install Consul on Debian    *****"
if [ ! -f /usr/local/bin/consul ]; then
    cd /tmp
    wget https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip
    unzip consul_${consul_version}_linux_amd64.zip
    sudo mv consul /usr/local/bin/
    consul -v
fi

echo "*****    Download and install Nomad on Debian    *****"
if [ ! -f /usr/local/bin/nomad ]; then
    cd /tmp
    wget https://releases.hashicorp.com/nomad/${nomad_version}/nomad_${nomad_version}_linux_amd64.zip
    unzip nomad_${nomad_version}_linux_amd64.zip
    sudo mv nomad /usr/local/bin/
    nomad -v
fi

echo "*****    gcloud login and get join addrs    *****"
sudo echo '${credentials}' > /var/gcp_key.json
gcloud auth activate-service-account --key-file=/var/gcp_key.json --project=${gcp_project}
export JOIN_ADDRS=$(gcloud compute instances list -r "gcp-consul-.*" --format=json | jq .[].networkInterfaces[0].networkIP | tr '\n' ',' | head -c-1)
export JOIN_ADDRS_NOMAD=$(gcloud compute instances list -r "gcp-consul-.*" --format=json | jq .[].networkInterfaces[0].networkIP | tr '\n' ',' | sed 's/",/:4647",/g' | head -c-1)
export MY_HOSTNAME=`hostname`
export MY_ADDR=$(gcloud compute instances list -r "`hostname`" --format=json | jq --raw-output .[].networkInterfaces[0].networkIP)
export MY_EXT_ADDR=$(gcloud compute instances list -r "`hostname`" --format=json | jq --raw-output .[].networkInterfaces[0].accessConfigs[0].natIP)
echo $JOIN_ADDRS

echo "*****    Consul - Create User / Group / Directorys    *****"
sudo groupadd --system consul
sudo useradd -s /sbin/nologin --system -g consul consul

sudo mkdir -p /var/lib/consul
sudo chown -R consul:consul /var/lib/consul
sudo chmod -R 775 /var/lib/consul

sudo mkdir -p /etc/consul.d
sudo chown -R consul:consul /etc/consul.d

echo "*****    Nomad - Create User / Group / Directorys    *****"
sudo groupadd --system nomad
sudo useradd -s /sbin/nologin --system -g nomad nomad

sudo mkdir -p /var/lib/nomad
sudo chown -R nomad:nomad /var/lib/nomad
sudo chmod -R 775 /var/lib/nomad

sudo mkdir /etc/nomad.d
sudo mv /tmp/nomad_agent.hcl /etc/nomad.d
sudo chown -R nomad:nomad /etc/nomad.d

sudo usermod -G docker -a nomad

echo "*****    Bootstrap Consul Client    *****"
sudo cat > /etc/consul.d/config.json << EOF
{
    "server": false,
    "advertise_addr": "$MY_EXT_ADDR",
    "advertise_addr_wan": "$MY_EXT_ADDR",
    "bind_addr": "$MY_ADDR",
    "client_addr": "$MY_ADDR",
    "datacenter": "${datacenter}",
    "data_dir": "/var/lib/consul",
    "encrypt": "${encrypt}",
    "log_level": "INFO",
    "enable_syslog": true,
    "leave_on_terminate": true,
    "start_join": [$JOIN_ADDRS],
    "ports": {
        "grpc": 8502
    },
    "connect": {
        "enabled": true
    },    
    "translate_wan_addrs": true
}
EOF

echo "*****    Bootstrap Nomad    *****"
echo "retry_join alternative servers = [ $JOIN_ADDRS_NOMAD ]"
sudo cat > /etc/nomad.d/client.hcl << EOF
data_dir  = "/var/lib/nomad"
datacenter = "${datacenter}"
region = "gcp"
bind_addr = "0.0.0.0"
advertise {
  # Defaults to the first private IP addressm or Port.
  http = "$MY_EXT_ADDR:4646"
  rpc  = "$MY_EXT_ADDR:4647"
  serf = "$MY_EXT_ADDR:4648"
}
client {
  enabled = true
  server_join {
    retry_join = [ "provider=gce project_name=${gcp_project} tag_value=nomad-server zone_pattern=asia-northeast1-.* credentials_file=/var/gcp_key.json" ]
    retry_max = 3
    retry_interval = "15s"
  }
  meta {
    "selector" = "nginx,haproxy"
  }
}
plugin "docker" {
  config {
  }
}
plugin "raw_exec" {
  config {
    enabled = true
  }
}
consul {
  address = "$MY_ADDR:8500"
  auto_advertse = true
  tags = ["agent", "gcp"]
}
EOF

echo "*****    Create and run consul service    *****"
sudo bash -c 'rm -rf /etc/systemd/system/consul.service'
cat << "EOF" | sudo tee -a /etc/systemd/system/consul.service
[Unit]
Description=Consul Service Discovery Agent
Documentation=https://www.consul.io/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=consul
Group=consul
ExecStart=${consul_excute}

ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=consul

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable consul
sudo systemctl start consul

echo "*****    Create and run nomad service    *****"
sudo bash -c 'rm -rf /etc/systemd/system/nomad.service'
cat << "EOF" | sudo tee -a /etc/systemd/system/nomad.service
[Unit]
Description=Nomad Agent
Documentation=https://www.nomadproject.io/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=nomad
Group=nomad
ExecStart=${nomad_excute}

ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=nomad

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable nomad
sudo systemctl start nomad