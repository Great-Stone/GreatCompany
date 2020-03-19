#! /bin/bash

echo "*****    Download Consul on ARM    *****"
if [ ! -f /usr/local/bin/consul ]; then
    cd /tmp
    wget https://releases.hashicorp.com/consul/1.6.1/consul_1.6.1_linux_arm.zip
    unzip consul_1.6.1_linux_arm.zip
    sudo mv consul /usr/local/bin/
    consul -v
fi

echo "*****    Install Consul on ARM    *****"
sudo groupadd --system consul
sudo useradd -s /sbin/nologin --system -g consul consul

sudo mkdir -p /var/lib/consul
sudo chown -R consul:consul /var/lib/consul
sudo chmod -R 775 /var/lib/consul

sudo mkdir /etc/consul.d
sudo chown -R consul:consul /etc/consul.d

echo "*****    Create and run consul service   *****"
#kill -9 `ps -ef | grep 'consul' | awk '{print $2}'`
sudo systemctl stop consul
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
ExecStart=/usr/local/bin/consul agent \
	-datacenter=private \
	-node=my-raspberry-pi \
	-bind=192.168.0.47 \
	-client=192.168.0.47 \
	-recursor 1.1.1.1 \
	-encrypt=h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o= \
	-data-dir=/var/lib/consul \
	-config-dir=/etc/consul.d \
	-retry-join=192.168.0.24

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