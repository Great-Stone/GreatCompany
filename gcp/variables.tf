variable "project" {
    default = "terraform-test-263205"
}
variable "region" {    
    default = "asia-northeast1"
}
variable "zone" {
    type    = list
    default = [
        "asia-northeast1-a",
        "asia-northeast1-b",
        "asia-northeast1-c"
    ]
}

variable "mode" {
    default = "dev"
}

variable "consul_server_name" {
    type    = list 
    default = [
        "consul-1",
        "consul-2",
        "consul-3"
    ]
}

variable "credentials_file" {
    default = "terraform-test-gcp.json"
}

variable "credentials" {
    default = ""
}