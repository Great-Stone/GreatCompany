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
variable "credentials" {
    default = file("terraform-test-gcp.json")
}