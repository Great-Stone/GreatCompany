#! /bin/bash

echo "*****    Download Nomad on ARM    *****"
if [ ! -f /usr/local/bin/nomad ]; then
    cd /tmp
    wget https://releases.hashicorp.com/nomad/0.10.4/nomad_0.10.4_linux_arm.zip
    unzip nomad_0.10.4_linux_arm.zip
    sudo mv nomad /usr/local/bin/
    nomad -v
fi

echo "*****    Install nomad on ARM    *****"
sudo groupadd --system nomad
sudo useradd -s /sbin/nologin --system -g nomad nomad

sudo mkdir -p /var/lib/nomad
sudo chown -R nomad:nomad /var/lib/nomad
sudo chmod -R 775 /var/lib/nomad

sudo mkdir /etc/nomad.d
sudo mv /tmp/nomad_agent.hcl /etc/nomad.d
sudo chown -R nomad:nomad /etc/nomad.d

sudo usermod -G docker -a nomad
sudo usermod -G docker -a consul
sudo usermod -G docker -a pi

echo "*****    Create and run nomad service   *****"
#kill -9 `ps -ef | grep 'nomad' | awk '{print $2}'`
sudo systemctl stop nomad
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
ExecStart=/usr/local/bin/nomad agent \
	-config=/etc/nomad.d \
	-encrypt=h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o=

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