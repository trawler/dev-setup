resource "aws_instance" "cluster-controller" {
  count         = var.controller_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.large"
  tags = {
    name    = format("%s-controller-%d", var.cluster_name, count.index)
    pet     = true
    project = var.project_label
  }
  disable_api_termination     = true
  key_name                    = var.public_key_name
  subnet_id                   = aws_subnet.cluster-subnet.id
  vpc_security_group_ids      = [aws_security_group.cluster_allow_ssh.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
    agent       = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname controller-${count.index}",
      "sudo add-apt-repository -y ppa:longsleep/golang-backports && sudo apt update",
      "sudo apt install -y golang-go",
      "sudo apt install -y make",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo usermod -aG docker $USER"
    ]
  }
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

output "controllers-public-dns" {
  value = aws_eip.controller-ext.*.public_dns
}

output "controllers-fqdn" {
  value = aws_route53_record.cluster-controller-record[*].fqdn
}
