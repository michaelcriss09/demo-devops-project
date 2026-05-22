resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr #"10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    name = "${var.env}-main"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}