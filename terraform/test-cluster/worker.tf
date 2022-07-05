/*
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_instance" "cluster-workers" {
  count                   = var.worker_count
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = "t2.large"
  disable_api_termination = false
}
*/

resource "aws_instance" "cluster-workers" {
  count         = var.worker_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.node_flavor
  user_data     = file("user_data/system-setup.sh")
  tags = {
    Name                                                   = format("%s-worker-%d", var.cluster_name_prefix, count.index)
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
  #     //"sudo hostnamectl set-hostname ${aws_instance.cluster-workers[count.index].private_dns}",
  #     "sudo add-apt-repository -y ppa:longsleep/golang-backports && sudo apt update",
  #     "sudo apt install -y golang-go",
  #     "sudo apt install -y make",
  #     "curl -fsSL https://get.docker.com -o get-docker.sh",
  #     "sudo sh get-docker.sh",
  #     "sudo usermod -aG docker $USER"
  #   ]
  # }

}

resource "aws_eip" "worker-ext" {
  count    = var.worker_count
  instance = aws_instance.cluster-workers[count.index].id
  vpc      = true
}

resource "aws_route53_record" "cluster-worker-record" {
  count   = var.worker_count
  zone_id = data.aws_route53_zone.cluster_domain.zone_id
  name    = format("worker-%d.%s", count.index, var.cluster_domain)
  type    = "CNAME"
  ttl     = "300"
  records = [aws_eip.worker-ext[count.index].public_dns]
}

