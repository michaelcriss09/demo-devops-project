resource "aws_eks_cluster" "eks" {
  name     = "${var.env}-eks-cluster"
  version  = var.eks_version
  role_arn = var.eks_role_arn

  upgrade_policy {
    support_type = "STANDARD"
  }

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true

    subnet_ids = [
      var.priv_subnet_1, var.priv_subnet_2
    ]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }
}

resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.eks.name
  version         = var.eks_version
  node_group_name = "general"
  node_role_arn   = var.node_role_arn

  subnet_ids = [
    var.priv_subnet_1, var.priv_subnet_2
  ]

  capacity_type  = var.node_capacity_time #"ON_DEMAND"
  instance_types = var.node_instance_type #["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 10
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}