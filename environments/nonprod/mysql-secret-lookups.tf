data "aws_secretsmanager_secret" "mysql_app" {
  name = "vprofile/nonprod/mysql-app"
}

data "aws_secretsmanager_secret" "mysql_migrator" {
  name = "vprofile/nonprod/mysql-migrator"
}