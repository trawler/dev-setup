provider "aws" {
  region = "eu-west-1"
}

resource "aws_key_pair" "kalmog-key" {
  key_name   = "kalmog-key"
  public_key = file("~/.ssh/id_aws.pub")
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


resource "aws_instance" "kalmog-dev" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  tags = {
    Name = "kalmog-dev"
  }
  key_name                    = "kalmog-key"
  subnet_id                   = aws_subnet.kalmog-test-subnet.id
  vpc_security_group_ids      = [aws_security_group.kalmog_allow_ssh.id]
  associate_public_ip_address = true

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_aws")
    host        = self.public_ip
    agent       = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo add-apt-repository -y ppa:longsleep/golang-backports && sudo apt update",
      "sudo apt install -y golang-go",
      "sudo apt install -y make"
    ]
  }
}

resource "aws_eip" "kalmog-test-env" {
  instance = aws_instance.kalmog-dev.id
  vpc      = true
}

output "kalmog-external-ip" {
  value = aws_eip.kalmog-test-env.public_ip
}
