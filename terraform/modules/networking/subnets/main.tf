resource "aws_subnet" "subnets" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = var.ip_on_launch

  tags = {
    "Name"                                  = "${var.env}-${var.purpose}-${var.availability_zone}"
    "Kubernetes.io/role/${var.tag}"         = "1"
    "Kubernetes.io/cluster/${var.eks_name}" = "owned"
  }
}