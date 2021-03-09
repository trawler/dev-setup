/*
data "aws_availability_zones" "available" {
  state = "available"
}

*/
resource "aws_instance" "cluster-workers" {
  count                   = var.worker_count
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = "t2.large"
  disable_api_termination = true

  tags = {
    Name = format("%s-worker-%d", var.cluster_name, count.index)
    pet  = true
  }
  key_name                    = var.public_key_name
  subnet_id                   = aws_subnet.cluster-subnet.id
  vpc_security_group_ids      = [aws_security_group.cluster_allow_ssh.id]
  associate_public_ip_address = true
  // availability_zone           = data.aws_availability_zones.available.names[count.index]

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
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
      "sudo hostnamectl set-hostname worker-${count.index}",
      "sudo add-apt-repository -y ppa:longsleep/golang-backports && sudo apt update",
      "sudo apt install -y golang-go",
      "sudo apt install -y make",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo usermod -aG docker $USER"
    ]
  }
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

output "worker-public-dns" {
  value = aws_instance.cluster-workers.*.public_dns
}

output "workers-fqdn" {
  value = aws_route53_record.cluster-worker-record[*].fqdn
}
