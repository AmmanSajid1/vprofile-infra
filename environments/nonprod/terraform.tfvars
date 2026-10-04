# terraform.tfvars (nonprod)

environment              = "nonprod"
aws_region               = "us-east-1"
project_name             = "vprofile-infra"
vpc_cidr                 = "10.0.0.0/16"
public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
private_db_subnet_cidrs  = ["10.0.12.0/24", "10.0.13.0/24"]
availability_zones       = ["us-east-1a", "us-east-1b"]
nat_gateway_count        = 1


