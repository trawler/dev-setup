locals {
  name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  cluster_version = "1.23"
  region          = "eu-west-1"
  cluster_name    = "k0s-imagebuilder-${random_string.suffix.result}"
  tags = {
    Owner = "kalmog@mirantis.com"
  }
}

locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = module.eks.cluster_id
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = module.eks.cluster_id
        user    = "terraform"
      }
    }]
    users = [{
      name = "terraform"
      user = {
        token = data.aws_eks_cluster_auth.this.token
      }
    }]
  })
}

terraform {
  backend "s3" {
    bucket = "k0sproject-scalable-runners-state"
    key    = "k0s-imagebuilder-eks/terraform.tfstate"
    region = "eu-west-1"
  }
}
