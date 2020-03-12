provider "google" {
  version = "3.5.0"

  credentials = var.credentials == "" ? file(var.credentials_file) : var.credentials

  project = var.project
  region  = var.region
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network-${var.mode}"
}

resource "google_compute_instance" "vm_instance" {
  count = length(var.zone)

  name         = "terraform-instance-${var.mode}-${count.index}"
  machine_type = "f1-micro"
  tags         = ["web", "dev"]
  zone         = var.zone[count.index]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}