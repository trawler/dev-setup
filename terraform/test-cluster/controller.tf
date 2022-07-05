data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "ebs_mount.cfg"
    content_type = "text/cloud-config"
    content      = file("user_data/ebs-mount.sh")
  }
  part {
    filename     = "system-setup.cfg"
    content_type = "text/cloud-config"
    content      = file("user_data/system-setup.sh")
  }
}

resource "aws_instance" "cluster-controller" {
  count         = var.controller_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.node_flavor
  user_data     = data.template_cloudinit_config.config.rendered
  tags = {
    Name                                                   = format("%s-controller-%d", var.cluster_name_prefix, count.index)
    pet                                                    = true
    project                                                = var.project_label
    format("kubernetes.io/cluster/%s", local.cluster_name) = "owned"
    format("k8s.io/cluster/%s", local.cluster_name)        = "owned"
  }

  key_name                    = var.public_key
  subnet_id                   = aws_subnet.cluster-subnet.id
  vpc_security_group_ids      = [aws_security_group.cluster_allow_ssh.id]
  associate_public_ip_address = true
  iam_instance_profile        = "k0s_cluster_node"

  source_dest_check = false
  root_block_device {
    volume_type = "gp2"
    volume_size = var.volume_size
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
    agent       = true
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     //"sudo hostnamectl set-hostname ${aws_instance.cluster-controller[count.index].private_dns}",
  #     "sudo add-apt-repository -y ppa:longsleep/golang-backports && sudo apt update",
  #     "sudo apt install -y golang-go",
  #     "sudo apt install -y make",
  #     "curl -fsSL https://get.docker.com -o get-docker.sh",
  #     "sudo sh get-docker.sh",
  #     "sudo usermod -aG docker $USER",
  #     "sudo snap install kubectl --classic",
  #     "sudo snap install helm --classic"
  #   ]
  # }
}

resource "aws_eip" "controller-ext" {
  count    = var.controller_count
  instance = aws_instance.cluster-controller[count.index].id
  vpc      = true
}

resource "aws_route53_record" "cluster-controller-record" {
  count   = var.controller_count
  zone_id = data.aws_route53_zone.cluster_domain.zone_id
  name    = format("controller-%d.%s", count.index, var.cluster_domain)
  type    = "CNAME"
  ttl     = "300"
  records = [aws_eip.controller-ext[count.index].public_dns]
}

data "aws_ebs_volume" "dev_home_ebs" {
  most_recent = true

  filter {
    name   = "volume-type"
    values = ["gp3"]
  }

  filter {
    name   = "tag:Name"
    values = ["kalmog-dev-mount"]
  }
}
resource "aws_volume_attachment" "dev_home" {
  device_name = "/dev/xvdf"
  volume_id   = data.aws_ebs_volume.dev_home_ebs.id
  instance_id = aws_instance.cluster-controller[0].id
}
