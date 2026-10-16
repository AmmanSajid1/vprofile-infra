resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "1.2.1"
  namespace        = "external-secrets"
  create_namespace = true

  wait          = true
  wait_for_jobs = true
  atomic        = true
  timeout       = 600

  values = [
    yamlencode({
      installCRDs = true

      serviceAccount = {
        create = true
        name   = "external-secrets"
      }

      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
        limits = {
          memory = "256Mi"
        }
      }
    })
  ]
}