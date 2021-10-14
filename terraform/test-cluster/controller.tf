resource "aws_instance" "cluster-master" {
  count         = var.master_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.large"
  tags = {
    Name = format("%s-controller-%d", var.cluster_name, count.index)
  }
  disable_api_termination     = false
  key_name                    = var.public_key
  subnet_id                   = aws_subnet.cluster-subnet.id
  vpc_security_group_ids      = [aws_security_group.cluster_allow_ssh.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 50
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_aws")
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

resource "aws_eip" "master-ext" {
  count    = var.master_count
  instance = aws_instance.cluster-master[count.index].id
  vpc      = true
}

output "cluster-external-ip" {
  value = aws_eip.master-ext.*.public_ip
}
