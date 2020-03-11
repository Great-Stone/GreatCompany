variable "connections" {
  type = map(object({
    type = string
    user = string
    private_key = string
    host = string
  }))
  default = {
    "pi-1" = {
        type = "ssh"
        user = "pi"
        private_key = "./.ssh/id_rsa"
        host = "192.168.0.47"
    }
  }
}