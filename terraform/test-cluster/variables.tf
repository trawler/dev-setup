variable "cluster_name" {
  type    = string
  default = "kalmog-mke"
}

variable "master_count" {
  type    = number
  default = 1
}

variable "worker_count" {
  type    = number
  default = 3
}