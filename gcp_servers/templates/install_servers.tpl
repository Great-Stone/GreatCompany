#! /bin/bash

echo "*****    Installing Utils    *****"
sudo apt update
sudo apt install -y unzip ufw jq
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

echo "*****    Bootstrap Consul    *****"
sudo cat > /etc/consul.d/config.json << EOF
{
    "server": true,
    "advertise_addr": "$MY_EXT_ADDR",
    "advertise_addr_wan": "$MY_EXT_ADDR",
    "bind_addr": "$MY_ADDR",
    "bootstrap_expect": 3,
    "client_addr": "$MY_ADDR",
    "datacenter": "${datacenter}",
    "data_dir": "/var/lib/consul",
    "node_name": "$MY_HOSTNAME",
    "enable_script_checks": true,
    "ports": {
      "http": 8500,
      "dns": 8600,
      "server": 8300,
      "serf_lan": 8301,
      "serf_wan": 8302
    },
    "recursors": [ "8.8.8.8" ],
    "translate_wan_addrs": true,
    "enable_syslog": true,
    "encrypt": "${encrypt}",
    "leave_on_terminate": true,
    "log_level": "INFO",
    "rejoin_after_leave": true,
    "retry_join": [$JOIN_ADDRS],
    "start_join": [$JOIN_ADDRS],
    "ui": true
}
EOF

echo "*****    Bootstrap Nomad    *****"
sudo cat > /etc/nomad.d/server.hcl << EOF
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
server {
  enabled = true
  bootstrap_expect = 3
  server_join {
    retry_join = [ $JOIN_ADDRS ]
    retry_max = 3
    retry_interval = "15s"
  }
  encrypt = "${encrypt}"
  node_gc_threshold = "20s"
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
  server_service_name = "gcp-nomad"
  client_service_name = "gcp-nomad-client"
  auto_advertise      = true
  server_auto_join    = true
  client_auto_join    = true
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