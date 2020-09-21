terraform {
  backend "s3" {
    bucket = "kalmog-tf-state"
    region = "eu-west-1"
    key = "terraform.tfstate"
  }
}