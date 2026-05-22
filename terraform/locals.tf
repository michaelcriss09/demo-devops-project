locals {
  vpc = {
    cidr = "10.0.0.0/16"
  }

  subnets = {
    public_zone1 = {
      cidr_block        = "10.0.64.0/19"
      availability_zone = "us-east-2a"
      ip_on_launch      = true
      tag               = "elb"
      purpose           = "public"
    }

    public_zone2 = {
      cidr_block        = "10.0.96.0/19"
      availability_zone = "us-east-2b"
      ip_on_launch      = true
      tag               = "elb"
      purpose           = "public"
    }

    private_zone1 = {
      cidr_block        = "10.0.0.0/19"
      availability_zone = "us-east-2a"
      ip_on_launch      = false
      tag               = "internal-elb"
      purpose           = "private"
    }

    private_zone2 = {
      cidr_block        = "10.0.32.0/19"
      availability_zone = "us-east-2b"
      ip_on_launch      = false
      tag               = "internal-elb"
      purpose           = "private"
    }
  }

  eks = {
    eks_version        = "1.30"
    node_instance_type = ["t3.medium"]
    node_capacity_time = "ON_DEMAND"
  }
}