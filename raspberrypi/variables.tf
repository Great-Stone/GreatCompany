variable "server_ip" {
    default = "192.168.0.47"
}

// variable "password" {}

variable "need_update" {
    description = "If [Y/y] then update.: "
}

variable "connections" {
    type = map(string)
    default = [
        {
            type = "ssh"
            user = "pi"
            private_key = "./.ssh/id_rsa"
            host = "192.168.0.47"
        },        
        {
            type = "ssh"
            user = "pi"
            private_key = "./.ssh/id_rsa"
            host = "192.168.0.47"
        }
    ]
}