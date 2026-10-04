module "vpc" {
  source                   = "../../modules/vpc"
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  availability_zones       = var.availability_zones
  nat_gateway_count        = var.nat_gateway_count

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }

}

module "eks" {
  source                          = "../../modules/eks"
  cluster_name                    = var.cluster_name
  cluster_admin_arn               = var.cluster_admin_arn
  k8s_version                     = var.k8s_version
  private_app_subnet_ids          = module.vpc.private_app_subnet_ids
  node_instance_type              = var.node_instance_type
  node_desired_capacity           = var.node_desired_capacity
  node_max_capacity               = var.node_max_capacity
  node_min_capacity               = var.node_min_capacity
  public_api_endpoint_access      = var.public_api_endpoint_access
  private_api_endpoint_access     = var.private_api_endpoint_access
  public_api_access_allowed_cidrs = var.public_api_access_allowed_cidrs

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}