provider "google" {
  version = "3.5.0"

  credentials = var.credentials

  project = var.project
  region  = var.region
  zone    = var.zone_a
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}