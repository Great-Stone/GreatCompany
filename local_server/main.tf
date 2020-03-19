locals {
  address = "192.168.0.24"
  ex-address = "121.130.137.31"
  consul-address = "127.0.0.1:8500"
}

resource "null_resource" "isntall_consul_by_choco" {
  provisioner "local-exec" {
    command = <<EOT
      echo "*****    Network    *****"
      # New-NetFirewallRule -Direction Inbound -DisplayName "consul-server" -Name "consul-server" -RemoteAddress 192.168.0.0/24 -Action Allow -EdgeTraversalPolicy Allow -Protocol TCP -LocalPort 8301,8300,1281,21000-21255
      # New-NetFirewallRule -Direction Inbound -DisplayName "consul-dns" -Name "consul-dns" -RemoteAddress 192.168.0.0/24 -Action Allow -EdgeTraversalPolicy Allow -Protocol TCP -LocalPort 53
      # New-NetFirewallRule -Direction Inbound -DisplayName "nomad-server" -Name "nomad-server" -RemoteAddress 192.168.0.0/24 -Action Allow -EdgeTraversalPolicy Allow -Protocol TCP -LocalPort 4646,4647,4648

      # Consul DNS
      # Set-DNSClientServerAddress -interfaceAlias "이더넷" -ServerAddresses ("127.0.0.1","168.126.63.1","168.126.63.2")

      echo "*****    install chocolatey    *****"
      $CHOCO_VERSION = (Get-Command "choco" -ErrorAction SilentlyContinue).Version
      if(!$CHOCO_VERSION){Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))}
      
      echo "*****    install Consul & Nomad on Windows    *****"
      choco install -y consul nomad bind-toolsonly
      New-Item -ItemType directory -Path C:\ProgramData\consul\data

      echo "*****    Consul Single Server    *****"
      Stop-Service -Name consul
      sc.exe delete consul
      sc.exe create consul binPath= "consul agent -server -ui -bootstrap-expect=1 -datacenter=private -advertise=${local.address} -client=0.0.0.0 -bind=${local.address} -serf-wan-bind=${local.address} -dns-port=53 -advertise-wan=${local.ex-address} -recursor 127.0.0.1 -encrypt=h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o= -data-dir=C:\ProgramData\consul\data -node=consul-01 -config-dir=C:\ProgramData\consul\config" start= auto
      Start-Service -Name consul
      dig "@127.0.0.1" -p 53 consul-01.node.consul
      dig consul-01.node.consul
      # consul join -wan <server>

      echo "*****    Nomad Single Server    *****"
      $env:NOMAD_ADDR=http://${local.address}:4646
      Stop-Service -Name nomad      
      sc.exe delete nomad
      sc.exe create nomad binPath= "nomad agent -server -node=nomad-01 -bootstrap-expect=1 -dc=private -region=local -bind=${local.address} -consul-address=${local.consul-address} -consul-auto-advertise -consul-server-auto-join -encrypt=h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o= -data-dir=C:\ProgramData\nomad\data -config=C:\ProgramData\nomad\conf" start= auto
      Start-Service -Name nomad
      # nomad server join <server>
    EOT

    interpreter = ["PowerShell", "-Command"]
  }

  triggers = {
    always_run = timestamp()
  }
}