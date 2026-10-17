resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = "1.19.0"
  namespace        = "external-dns"
  create_namespace = true

  wait    = true
  atomic  = true
  timeout = 600

  values = [
    yamlencode({
      provider = {
        name = "aws"
      }

      sources = ["ingress"]

      domainFilters = ["ammandevops.xyz"]

      extraArgs = [
        "--zone-id-filter=Z085098720M5FBDE8GFB2"
      ]

      policy     = "upsert-only"
      registry   = "txt"
      txtOwnerId = "vprofile-nonprod"
      txtPrefix  = "external-dns-"

      serviceAccount = {
        create = true
        name   = "external-dns"
      }

      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
        limits = {
          memory = "128Mi"
        }
      }
    })
  ]
}