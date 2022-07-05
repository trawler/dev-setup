resource "random_string" "suffix" {
  length  = 8
  special = false
}
locals {
  cluster_name = "${var.cluster_name_prefix}-${random_string.suffix.result}"
}

variable "cluster_name_prefix" {
  type    = string
  default = "kalmog-k0s"
}

variable "controller_count" {
  type    = number
  default = 1
}

variable "worker_count" {
  type    = number
  default = 3
}

variable "cluster_domain" {
  type    = string
  default = "trawler.sh"
}

variable "public_key" {
  type    = string
  default = "kalmog-key"
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/id_aws"
}

variable "project_label" {
  type    = string
  default = "KOS"
}


variable "node_flavor" {
  type    = string
  default = "g3.4xlarge"
}

variable "volume_size" {
  type    = string
  default = "150"
}

