// sudo journalctl -u google-startup-scripts.service
provider "google" {
  version = "3.5.0"

  credentials = var.credentials == "" ? file(var.credentials_file) : var.credentials

  project = var.project
  region  = var.region
}

locals {  
  credentials = var.credentials == "" ? file(var.credentials_file) : var.credentials
}

data "template_file" "startup_script" {
  // Caution!! file line Sequence
  template = file("${path.module}/templates/install_servers.tpl")

  vars = {
    gcp_project = var.project
    consul_version = "1.7.1",
    nomad_version = "0.10.4",
    private_consul_addr = "121.130.137.31",
    datacenter = var.region,
    encrypt = "h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o=",
    consul_excute = "/usr/local/bin/consul agent -config-dir=/etc/consul.d"
    nomad_excute = "/usr/local/bin/nomad agent -config=/etc/nomad.d"
    credentials = local.credentials
  }
}

resource "google_compute_firewall" "default" {
  name    = "consul-server-firewall"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [
      "80",
      "8300", # Consul Server RPC
      "8301", # Consul Serf LAN
      "8302", # Consul Serf WAN
      "8400",  # Consul RPC
      "8500",  # Consul UI
      "8600",  # Consul DNS Interface
      "4646",  # Nomad Http
      "4647",  # Nomad Rpc
      "4648"  # Nomad Serf
    ]
  }

  source_ranges = ["0.0.0.0/0"]
  source_tags = ["consul-server"]
}

resource "google_compute_address" "static" {
  name = "first-address"
}

resource "google_compute_instance" "consul_servers" {
  count = length(var.zone) != 3 ? 0 : 3

  name         = var.consul_server_name[count.index]
  machine_type = "f1-micro"
  tags         = ["consul-server", "nomad-server"]
  zone         = var.zone[count.index]
  labels       = { "mode" = "server" }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  
  metadata_startup_script = data.template_file.startup_script.rendered

  network_interface {
    network = "default"
    access_config {
      nat_ip = count.index == 0 ? google_compute_address.static.address : ""
    }
  }
}

output "external_ip" {
  value = google_compute_instance.consul_servers[0].network_interface.0.access_config.0.nat_ip
}

output "internal_ip" {
  value = google_compute_instance.consul_servers[*].network_interface.0.network_ip
}