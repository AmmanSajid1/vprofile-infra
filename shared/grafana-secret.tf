resource "aws_secretsmanager_secret" "grafana_admin" {
  name        = "vprofile/nonprod/grafana_admin"
  description = "Grafana admin credentials for nonprod monitoring"

  recovery_window_in_days = 7

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = "nonprod"
    Purpose     = "monitoring-admin-credentials"
  }
}