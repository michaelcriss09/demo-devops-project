# Networking - VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

# Networking - Subnets
output "public_subnet_zone1_id" {
  description = "ID of the public subnet in us-east-2a"
  value       = module.subnets["public_zone1"].subnet_id
}

output "public_subnet_zone2_id" {
  description = "ID of the public subnet in us-east-2b"
  value       = module.subnets["public_zone2"].subnet_id
}

output "private_subnet_zone1_id" {
  description = "ID of the private subnet in us-east-2a"
  value       = module.subnets["private_zone1"].subnet_id
}

output "private_subnet_zone2_id" {
  description = "ID of the private subnet in us-east-2b"
  value       = module.subnets["private_zone2"].subnet_id
}

# Networking - NAT & Routing
output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.nat.nat_id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.route_tables.public_route_table_id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = module.route_tables.private_route_table_id
}

# EKS
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.EKS.eks_name
}

output "eks_oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster"
  value       = module.EKS.oidc_url
}

# IAM Roles
output "eks_role_arn" {
  description = "ARN of the IAM role for the EKS control plane"
  value       = module.roles.eks_role_arn
}

output "node_role_arn" {
  description = "ARN of the IAM role for the EKS worker nodes"
  value       = module.roles.node_role_arn
}
