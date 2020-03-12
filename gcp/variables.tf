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
    ]
}
variable "credentials_file" {
    default = "terraform-test-gcp.json"
}
variable "credentials" {
    default = ""
}
variable "mode" {
    default = "dev"
}