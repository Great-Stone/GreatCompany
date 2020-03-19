locals {
  timestamp = timestamp()
}

resource "null_resource" "provisioning_raspberry_pi" {  
  for_each = var.connections

  connection {    
    type = each.value.type
    user = each.value.user
    private_key = file(each.value.private_key)
    host = each.value.host
  }

  provisioner "file" {
    source      = "script/install_utils.sh"
    destination = "/tmp/install_utils.sh"
  }

  provisioner "file" {
    source      = "script/install_consul.sh"
    destination = "/tmp/install_consul.sh"
  }

  provisioner "file" {
    source      = "script/install_nomad.sh"
    destination = "/tmp/install_nomad.sh"
  }

  provisioner "file" {
    source      = "config/nomad_agent.hcl"
    destination = "/tmp/nomad_agent.hcl"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_*.sh",
      "/tmp/install_utils.sh",
      "/tmp/install_consul.sh",
      "/tmp/install_nomad.sh"
    ]
  }

  triggers = {
    always_run = local.timestamp
  }
}