// sudo journalctl -u google-startup-scripts.service
provider "google" {
  version = "3.5.0"

  credentials = var.credentials == "" ? file(var.credentials_file) : var.credentials

  project = var.project
  region  = var.region
}

locals {
  join_list = "[${var.consul_server_name[0]}, ${var.consul_server_name[1]}, ${var.consul_server_name[2]}]"
  credentials = var.credentials == "" ? file(var.credentials_file) : var.credentials
}

data "template_file" "startup_script" {
  // Caution!! file line Sequence
  template = file("${path.module}/templates/install_agents.tpl")

  vars = {
    gcp_project = var.project
    consul_version = "1.7.1",
    nomad_version = "0.10.4",
    private_consul_addr = "121.130.137.31",
    datacenter = var.region,
    encrypt = "h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o=",
    join_list = local.join_list,
    consul_excute = "/usr/local/bin/consul agent -config-dir=/etc/consul.d"
    nomad_excute = "/usr/local/bin/nomad agent -config=/etc/nomad.d"
    credentials = local.credentials
  }
}

resource "google_compute_firewall" "default" {
  name    = "consul-agent-firewall"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [
      "1936", # HAProxy - monitoring
      "8080", # HAProxy - service
    ]
  }

  source_ranges = ["0.0.0.0/0"]
  source_tags = ["consul-agent"]
}

resource "google_compute_instance" "service_vm" {
  count = length(var.zone) != 3 ? 0 : 3

  name         = var.consul_server_name[count.index]
  machine_type = "f1-micro"
  tags         = ["consul-server", "consul-agent"]
  zone         = var.zone[count.index]
  labels       = { "mode" = "services" }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  
  metadata_startup_script = data.template_file.startup_script.rendered

  network_interface {
    network = "default"
    access_config {
    }
  }
}

output "services-vm-external_ip" {
  value = google_compute_instance.service_vm[*].network_interface.0.access_config.0.nat_ip
}

output "services-vm-internal_ip" {
  value = google_compute_instance.service_vm[*].network_interface.0.network_ip
}