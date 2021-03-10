provider "aws" {
  region = "eu-west-1"
}

resource "aws_key_pair" "kalmog-key" {
  key_name   = var.public_key_name
  public_key = file(format("%s.pub", var.private_key_path))
}

resource "aws_security_group" "kalmog_allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.kalmog-vpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kalmog-allow_ssh"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "aws_route53_zone" "trawler" {
  name         = var.dev-env_domain
  private_zone = false
}

resource "aws_instance" "kalmog-dev" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.xlarge"
  tags = {
    name    = var.dev-env_name
    pet     = true
    project = var.project_label
  }
  key_name                    = var.public_key_name
  subnet_id                   = aws_subnet.kalmog-test-subnet.id
  vpc_security_group_ids      = [aws_security_group.kalmog_allow_ssh.id]
  associate_public_ip_address = true
  disable_api_termination     = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 30
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
      "sudo add-apt-repository -y ppa:longsleep/golang-backports && sudo apt update",
      "sudo apt install -y golang-go",
      "sudo apt install -y make",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo usermod -aG docker $USER"
    ]
  }
}

resource "aws_eip" "kalmog-test-env" {
  instance = aws_instance.kalmog-dev.id
  vpc      = true
}

resource "aws_route53_record" "kalmog-dev" {
  zone_id = data.aws_route53_zone.trawler.zone_id
  name    = format("%s.%s", var.dev-env_name, var.dev-env_domain)
  type    = "CNAME"
  ttl     = "300"
  records = [aws_eip.kalmog-test-env.public_dns]
}

output "kalmog-external-dns" {
  value = aws_instance.kalmog-dev.public_dns
}

output "kalmog-dev-fqdn" {
  value = aws_route53_record.kalmog-dev.fqdn
}
