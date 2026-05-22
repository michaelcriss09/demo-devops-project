module "vpc" {
  source = "./modules/networking/vpc"

  vpc_cidr = local.vpc.cidr
  env      = var.env
}

module "subnets" {
  source   = "./modules/networking/subnets"
  for_each = local.subnets

  vpc_id            = module.vpc.vpc_id
  subnet_cidr       = each.value.cidr_block
  availability_zone = each.value.availability_zone
  ip_on_launch      = each.value.ip_on_launch

  eks_name = "${var.env}-eks-cluster"
  env      = var.env
  tag      = each.value.tag
  purpose  = each.value.purpose
}

module "nat" {
  source    = "./modules/networking/nat"
  env       = var.env
  subnet_id = module.subnets["public_zone1"].subnet_id
}

module "route_tables" {
  source = "./modules/networking/routing"

  vpc_id = module.vpc.vpc_id
  igw_id = module.vpc.igw_id.id
  nat_id = module.nat.nat_id

  env = var.env
}

module "route_associations" {
  source         = "./modules/networking/routing/associations"
  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id

  for_each = {
    public_subnet1 = {
      subnet_id      = module.subnets["public_zone1"].subnet_id
      route_table_id = module.route_tables.public_route_table_id
    }
    public_subnet2 = {
      subnet_id      = module.subnets["public_zone2"].subnet_id
      route_table_id = module.route_tables.public_route_table_id
    }
    private_subnet1 = {
      subnet_id      = module.subnets["private_zone1"].subnet_id
      route_table_id = module.route_tables.private_route_table_id
    }
    private_subnet2 = {
      subnet_id      = module.subnets["private_zone2"].subnet_id
      route_table_id = module.route_tables.private_route_table_id
    }
  }
}

module "roles" {
  source = "./modules/eks/roles"
  env    = var.env 
}

module "EKS" {
  source = "./modules/eks"

  env                = var.env
  eks_version        = local.eks.eks_version
  priv_subnet_1      = module.subnets["private_zone1"].subnet_id
  priv_subnet_2      = module.subnets["private_zone2"].subnet_id
  node_instance_type = local.eks.node_instance_type
  node_capacity_time = local.eks.node_capacity_time

  eks_role_arn  = module.roles.eks_role_arn
  node_role_arn = module.roles.node_role_arn
 
  depends_on = [module.roles]
} 

module "addon" {
    source = "./modules/eks/addon"
    
    env              = var.env
    eks_name         = module.EKS.eks_name
    eks_oidc_issuer_url = module.EKS.oidc_url
    
    depends_on = [module.EKS]
  
}