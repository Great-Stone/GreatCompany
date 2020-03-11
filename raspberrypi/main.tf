locals {
  timestamp = timestamp()
}

resource "null_resource" "update_raspberry_pi" {  
  for_each = var.connections

  connection {    
    type = each.value.type
    user = each.value.user
    private_key = file(each.value.private_key)
    host = each.value.host
  }

  provisioner "remote-exec" {
    inline = [
      "cat /etc/os-release",
      "uname -a",
      "sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y",      
    ]
  }

  triggers = {
    always_run = local.timestamp
  }
}
