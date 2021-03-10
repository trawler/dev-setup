variable "dev-env_name" {
  type    = string
  default = "kalmog-dev"
}

variable "dev-env_domain" {
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

variable "project_label" {
  type    = string
  default = "KOS"
}
