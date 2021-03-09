variable "cluster_name" {
  type    = string
  default = "kalmog-k0s"
}

variable "controller_count" {
  type    = number
  default = 3
}

variable "worker_count" {
  type    = number
  default = 3
}

variable "cluster_domain" {
  type    = string
  default = "trawler.sh"
}

variable "public_key_name" {
  type    = string
  default = "kalmog-key"
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/id_aws"
}