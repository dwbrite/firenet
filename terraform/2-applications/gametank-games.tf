# Vars

variable "gtg_postgresql_user" {
  description = "gtg user for postgres"
  type        = string
}

variable "gtg_postgresql_password" {
  description = "gtg password for postgres"
  type        = string
}

variable "gtg_postgresql_postgres_password" {
  description = "'postgres' password for postgres"
  type        = string
}

resource "kubernetes_namespace" "gametank-games" {
  metadata {
    name = "gametank-games"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_secret" "gametank-games-postgresql" {
  metadata {
    name      = "gametank-games-postgresql"
    namespace = kubernetes_namespace.gametank-games.metadata[0].name
  }

  data = {
    postgresql-user = var.gtg_postgresql_user
    postgresql-password = var.gtg_postgresql_password
    postgresql-postgres-password = var.gtg_postgresql_postgres_password
    postgresql-url = "postgres://${var.gtg_postgresql_user}:${var.gtg_postgresql_password}@gametank-games-postgresql:5432/gtg"
  }
}

resource "kubernetes_manifest" "gametank_games" {
  depends_on = [kubernetes_manifest.keycloak] // TODO: add a data source for this??
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "gametank-games"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/dwbrite/firenet.git"
        path           = "k8s/apps/gametank-games/base"
        targetRevision = "HEAD"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.gametank-games.metadata[0].name
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

resource "kubernetes_manifest" "vservice_gtg" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name = "vservice-gtg"
      namespace = kubernetes_namespace.gametank-games.metadata[0].name
    }
    spec = {
      hosts = ["gametank.games"]
      gateways = ["istio-system/gametank-games-gateway"]
      http = [
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
                host = "gtg"
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

