# Vars

variable "outline_postgresql_user" {
  description = "outline user for postgres"
  type        = string
}

variable "outline_postgresql_password" {
  description = "outline password for postgres"
  type        = string
}

variable "outline_postgresql_postgres_password" {
  description = "'postgres' password for postgres"
  type        = string
}

variable "outline_secret_key" {
  description = "secret key for outline?"
  type        = string
}


variable "outline_utils_secret" {
  description = "secret key for outline utils?"
  type        = string
}


# create a minio tenant with a bucket

resource "kubernetes_manifest" "minio-tenant-outline" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "minio-tenant-outline"
      namespace = "argocd" # TODO: PLEASE STOP HARD-CODING ME D;
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://operator.min.io/"
        targetRevision = "5.0.10"
        chart          = "tenant"
        helm = {
          values = <<-EOT
            tenant:
              name: outline
              pools:
                - servers: 1
                  name: minio-pool-outline
                  volumesPerServer: 1
                  size: 24Gi
              buckets:
                - name: outline # as described in deployments.yaml
                  region: local
                  objectLock: false
              certificate:
                requestAutoCert: false
          EOT
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.s3.metadata[0].name
      }
      syncPolicy = {
        automated = {}
      }
    }
  }
}

resource "kubernetes_namespace" "outline-wiki" {
  metadata {
    name = "outline-wiki"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_secret" "minio-bucket-access" {
  metadata {
    name      = "minio-bucket-access"
      namespace = kubernetes_namespace.outline-wiki.metadata[0].name
  }

  data = {
    access_key = "niPEM6wEA4sNEL5WIths"
    secret_key = "ncUNAndUiRbcpCNl54AD6DxRQCSbbMyxOGGcYxJU"
  }
}

resource "kubernetes_secret" "outline-wiki-postgresql" {
  metadata {
    name      = "outline-wiki-postgresql"
    namespace = kubernetes_namespace.outline-wiki.metadata[0].name
  }

  data = {
    postgresql-user = var.outline_postgresql_user // hard-coded to outline in the stateful set
    postgresql-password = var.outline_postgresql_password // TODO: change from cock
    postgresql-postgres-password = var.outline_postgresql_postgres_password
  }
}

resource "kubernetes_manifest" "outline_wiki" {
  depends_on = [kubernetes_manifest.keycloak] // TODO: add a data source for this??
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "outline-wiki"
      namespace = "argocd" # Replace with your desired namespace if needed
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/dwbrite/firenet.git"
        path           = "k8s/apps/outline-wiki/base"
        targetRevision = "HEAD"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.outline-wiki.metadata[0].name
      }
      syncPolicy = {
        automated = {
          selfHeal = true
          prune    = true
        }
      }
    }
  }
}

resource "kubernetes_manifest" "vservice_outline" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name = "vservice-outline"
      namespace = kubernetes_namespace.outline-wiki.metadata[0].name
    }
    spec = {
      hosts = ["outline.tiny.pizza", "outline.dwbrite.com"]
      gateways = ["istio-system/dwbrite-com-gateway", "istio-system/tiny-pizza-gateway"]
      http = [
        {
          match = [
            {
              port = 9000
            }
          ]
          route = [
            {
              destination = {
                host = "outline-hl.s3"
                port = {
                  number = 9000
                }
              }
            }
          ]
        },
        {
          match = [
            {
              port = 80
            },
            {
              port = 443
            }
          ]
          route = [
            {
              destination = {
                host = "outline"
                port = {
                  number = 80
                }
              }
            }
          ]
        }
      ]
    }
  }
}

