#! /bin/bash

echo "*****    OS Info    *****"
cat /etc/os-release
uname -a
sudo cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime

echo "*****    Installing Utils    *****"
sudo apt update
sudo apt install -y unzip ufw jq
sudo apt autoremove -y

sudo ufw allow 80
sudo ufw allow 8300
sudo ufw allow 8301
sudo ufw allow 8500
sudo ufw allow 8600
sudo ufw allow 4646 # nomad

sudo ufw allow 1936 # haproxy
sudo ufw allow 8080 # haproxy

sudo ufw allow 22
sudo ufw --force enable

# sudo curl -fsSL https://get.docker.com/ | sudo sh
# sudo usermod -aG docker pi