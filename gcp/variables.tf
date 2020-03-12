variable "project" {}
variable "region" {}
variable "zone" {
    type    = list
    default = [
        "asia-northeast1-a",
    ]
}
variable "credentials" {}