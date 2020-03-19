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
        "asia-northeast1-a",
        "asia-northeast1-c"
    ]
}

variable "mode" {
    default = "dev"
}

variable "consul_server_name" {
    type    = list 
    default = [
        "gcp-agent-1",
        "gcp-agent-2",
        "gcp-agent-3"
    ]
}

variable "credentials_file" {
    default = "terraform-test-gcp.json"
}

variable "credentials" {
    default = ""
}