provider "google" {
  version = "3.5.0"

  credentials = var.credentials == "" ? file(var.credentials_file) : var.credentials

  project = var.project
  region  = var.region
}

locals {
  single_exec = "/usr/local/bin/consul agent -server -ui -advertise=`curl ifconfig.me` -bind=`curl ifconfig.me` -data-dir=/var/lib/consul -node=`hostname -f` -config-dir=/etc/consul.d"  
  three_exec = "/usr/local/bin/consul agent -node=`hostname -f` -config-dir=/etc/consul.d"
  credentials = var.credentials == "" ? file(var.credentials_file) : var.credentials
}

// data "template_file" "single_exec" {
//   template = "/usr/local/bin/consul agent -server -ui -advertise=`curl ifconfig.me` -bind=`curl ifconfig.me` -data-dir=/var/lib/consul -node=`hostname -f` -config-dir=/etc/consul.d"  
// }

// data "template_file" "three_exec" {
//   template = "/usr/local/bin/consul agent -node=`hostname -f` -config-dir=/etc/consul.d"
// }

data "template_file" "startup_script" {
  // Caution!! file line Sequence
  template = file("${path.module}/templates/install_consul.tpl")

  vars = {
    gcp_project = var.project
    consul_version = "1.7.1",
    datacenter = var.region,
    encrypt = "h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o=",
    join_list = "[${var.consul_server_name[0]}, ${var.consul_server_name[1]}, ${var.consul_server_name[2]}]",
    excute = length(var.zone) != 3 ? local.single_exec : local.three_exec
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
      "8300", # Server RPC
      "8301", # Serf LAN
      "8302", # Serf WAN
      "8400",  # RPC
      "8500",  # UI
      "8600"  # DNS Interface
    ]
  }

  source_ranges = ["0.0.0.0/0"]
  source_tags = ["consul-server"]
}

resource "google_compute_instance" "consul_servers" {
  count = length(var.zone) != 3 ? 0 : 3

  name         = var.consul_server_name[count.index]
  machine_type = "f1-micro"
  tags         = ["consul-server"]
  zone         = var.zone[count.index]
  labels       = { "mode" = "server" }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  // sudo journalctl -u google-startup-scripts.service
  metadata_startup_script = data.template_file.startup_script.rendered

  network_interface {
    network = "default"
    access_config {
    }
  }
}

output "external_ip" {
  value = google_compute_instance.consul_servers[*].network_interface.0.access_config.0.nat_ip
}

output "internal_ip" {
  value = google_compute_instance.consul_servers[*].network_interface.0.network_ip
}