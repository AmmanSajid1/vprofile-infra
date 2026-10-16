resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.10.5"
  namespace        = "argocd"
  create_namespace = true

  wait    = true
  timeout = 600

  atomic        = true
  wait_for_jobs = true

  values = [
    yamlencode({
      controller = {
        replicas = 1

        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            memory = "512Mi"
          }
        }
      }

      repoServer = {
        replicas = 1

        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            memory = "512Mi"
          }
        }
      }

      server = {
        replicas = 1

        service = {
          type = "ClusterIP"
        }

        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            memory = "256Mi"
          }
        }
      }

      redis = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            memory = "128Mi"
          }
        }
      }

      applicationSet = {
        replicas = 1

        resources = {
          requests = {
            cpu    = "50m"
            memory = "128Mi"
          }
          limits = {
            memory = "256Mi"
          }
        }
      }

      dex = {
        enabled = false
      }

      notifications = {
        enabled = false
      }
    })
  ]


}