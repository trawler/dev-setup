resource "aws_vpc" "kalmog-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "kalmog-vpc"
  }
}

resource "aws_subnet" "kalmog-test-subnet" {
  cidr_block        = cidrsubnet(aws_vpc.kalmog-vpc.cidr_block, 3, 1)
  vpc_id            = aws_vpc.kalmog-vpc.id
  availability_zone = "eu-west-1a"
}

resource "aws_internet_gateway" "kalmog-test-env-gw" {
  vpc_id = aws_vpc.kalmog-vpc.id
  tags = {
    Name = "kalmog-test-env-gw"
  }
}

resource "aws_route_table" "route-table-kalmog-test-env" {
  vpc_id = aws_vpc.kalmog-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kalmog-test-env-gw.id
  }
  tags = {
    Name = "kalmog-test-env-route-table"
  }
}

resource "aws_route_table_association" "kalmog-subnet-association" {
  subnet_id      = aws_subnet.kalmog-test-subnet.id
  route_table_id = aws_route_table.route-table-kalmog-test-env.id
}