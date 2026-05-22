resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "${var.env}-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = var.subnet_id

  tags = {
    Name = "${var.env}-nat"
  }
}