output "input_need_update_value" {
  value = lower(var.need_update) == "y" ? true : false
}

locals {
  timestamp = timestamp()
}

resource "null_resource" "update_raspberry_pi" {  
  count = lower(var.need_update) == "y" ? 1 : 0
  
  // connection {
  //   type = "ssh"
  //   user = "pi"
  //   private_key = file("./.ssh/id_rsa")
  //   host = var.server_ip
  // }
  for (con in var.connections) {
    connection {
      type = con.type
      user = con.user
      private_key = file(con.private_key)
      host = con.host
    }
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
