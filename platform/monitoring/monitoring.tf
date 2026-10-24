resource "helm_release" "monitoring" {
  name             = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "92.10.1"
  namespace        = "monitoring"
  create_namespace = true

  wait    = true
  timeout = 900

  atomic = true

  values = [
    yamlencode({
      prometheus = {
        service = {
          type = "ClusterIP"
        }

        prometheusSpec = {
          replicas      = 1
          retention     = "7d"
          retentionSize = "8GB"

          resources = {
            requests = {
              cpu    = "150m"
              memory = "512Mi"
            }
            limits = {
              memory = "1Gi"
            }
          }

          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]

                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }

      grafana = {
        replicas = 1

        admin = {
          existingSecret = "grafana-admin-credentials"
          userKey        = "admin-user"
          passwordKey    = "admin-password"
        }

        service = {
          type = "ClusterIP"
        }

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

      alertmanager = {
        alertmanagerSpec = {
          replicas = 1

          resources = {
            requests = {
              cpu    = "25m"
              memory = "64Mi"
            }
            limits = {
              memory = "128Mi"
            }
          }
        }
      }

      prometheusOperator = {
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

      kubeStateMetrics = {
        enabled = true
      }

      nodeExporter = {
        enabled = true
      }

      kubeControllerManager = {
        enabled = false
      }

      kubeScheduler = {
        enabled = false
      }

      kubeEtcd = {
        enabled = false
      }

      kubeProxy = {
        enabled = false
      }
    })
  ]
}