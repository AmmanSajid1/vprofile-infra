data "aws_secretsmanager_secret" "grafana_admin" {
  name = "vprofile/nonprod/grafana_admin"
}