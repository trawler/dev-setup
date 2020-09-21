provider "aws" {
  region = "eu-west-1"
}

resource "aws_key_pair" "kalmog-key" {
  key_name   = "kalmog-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDejmUEu6L02syIpOguw6elCpeYIKu4xBZvav26fmZvHs+BuCh+URaShW/kCi3S+qKm84pjs4Kosh1B5m1oi8n9E7EO2d0gGeZF1gBtHFYfe5OeWo0mzZGaqvoU7TgFCiPduw71s7N9LVc1uLIx5Y4UM/KEYhDCV1IBgQa5aIFwCrcLnl721NK8JB3Sf1CuEU2Fky1GHM7biwdLlLEjA4RalpksgdlA5DqUlY8o9W2DsHlsY70f3njdBBio6ssrHw2sCjXCACO5Q+2gRPfuLjKnidEYFqUCfOKTO/BbxPctQHi8BwxqEbOrjR9OnzmzsdmrHiBClylE/L2XqKP1tRuMb56rKBCOgN8+z0oDqqeB39++zrOLxDq8T14knMFXHr1CGqEXJv2q77aFpXB2rm0pN2fkaknCIKhaQ9+XW3dVq4jY6kstufkXRwTyw/sNyW3vUA19PmAxQNecFd9PvOfaWPRAZBtuOc6I8OwvE8c6wzjTG4iaF8/8Zpue8cM96zTWb1a8bmLM46GTqgGYoohTFWbG/3i55rcUhhjO6eYS+AiyCga1eQlQfqWQ1S4ehVTXUqB51BMezeQfoOMRvMRWKtWl+qcbnON+bm4x0PCTNjQEtaR11CAHO+nqjCoVoBnd96k0N5PUkZwYJVvUk2pcBFHz9U+uqInF8BKeRldPCQ== karena@Karens-MBP.ber.coreos.systems"
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
  tags          = {
    Name        = "kalmog-dev"
  }
  key_name = "kalmog-key"
  security_groups = [aws_security_group.kalmog_allow_ssh.id]
  subnet_id = aws_subnet.kalmog-test-subnet.id
}

resource "aws_eip" "kalmog-test-env" {
  instance = aws_instance.kalmog-dev.id
  vpc      = true
}

output "kalmog-external-ip" {
  value = aws_eip.kalmog-test-env.public_ip
}
