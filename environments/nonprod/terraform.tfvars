# terraform.tfvars (nonprod)

# VPC Configuration
environment              = "nonprod"
aws_region               = "us-east-1"
project_name             = "vprofile-infra"
vpc_cidr                 = "10.0.0.0/16"
public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
private_db_subnet_cidrs  = ["10.0.12.0/24", "10.0.13.0/24"]
availability_zones       = ["us-east-1a", "us-east-1b"]
nat_gateway_count        = 1

# EKS configuration
cluster_name                    = "vprofile-nonprod-eks-cluster"
#cluster_admin_arn = "arn:aws:iam::<ACCOUNT_ID>:user/<ADMIN_USER>"
k8s_version                     = "1.35"
node_instance_type              = "t3.medium"
node_desired_capacity           = 2
node_max_capacity               = 3
node_min_capacity               = 1
public_api_endpoint_access      = true
private_api_endpoint_access     = true
public_api_access_allowed_cidrs = ["92.40.168.242/32"] #myip


