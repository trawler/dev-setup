variable "cluster_name" {
  type    = string
  default = "kalmog-k0s"
}

variable "master_count" {
  type    = number
  default = 1
}

variable "worker_count" {
  type    = number
  default = 3
}

variable "public_key" {
  type    = string
  default = "kalmog-key"
}