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