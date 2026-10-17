resource "aws_ssm_parameter" "rds_endpoint" {
  name  = "/vprofile/nonprod/rds/endpoint"
  type  = "String"
  value = module.rds.rds_address
}

resource "aws_ssm_parameter" "rds_master_secret_arn" {
  name  = "/vprofile/nonprod/rds/master-secret-arn"
  type  = "String"
  value = module.rds.master_user_secret_arn
}