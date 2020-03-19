data_dir  = "/var/lib/nomad"
datacenter = "private"
region = "local"
name = "my-raspberry-pi"
bind_addr = "192.168.0.47"
advertise {
  # Defaults to the first private IP addressm or Port.
  http = "192.168.0.47:4646"
  rpc  = "192.168.0.47:4647"
  serf = "192.168.0.47:4648"
}

client {
  enabled = true
  servers = ["192.168.0.24:4647"]
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
  address = "192.168.0.47:8500"
}