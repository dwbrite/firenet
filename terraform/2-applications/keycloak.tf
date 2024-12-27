# vars

variable "keycloak_admin_username" {
  description = "Admin username for Keycloak"
  type        = string
}

variable "keycloak_admin_password" {
  description = "Admin password for Keycloak"
  type        = string
}


resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = "keycloak"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_persistent_volume_claim" "keycloak_theme_pvc" {
  metadata {
    name      = "keycloak-theme-pvc"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

# real shit

resource "kubernetes_secret" "keycloak_admin_secret" {
  metadata {
    name      = "keycloak-admin-creds"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  data = {
    username = var.keycloak_admin_username
    password = var.keycloak_admin_password
  }
}

resource "kubernetes_manifest" "keycloak" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "keycloak"
      namespace = "argocd" # TODO: PLEASE STOP HARD-CODING ME D;
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://charts.bitnami.com/bitnami"
        targetRevision = "17.3.6"
        chart          = "keycloak"
        helm           = {
          values = <<-EOT
            proxy: edge
            production: true
            auth:
              adminUser: "${kubernetes_secret.keycloak_admin_secret.data.username}"
              existingSecret: "${kubernetes_secret.keycloak_admin_secret.metadata[0].name}"
              passwordSecretKey: "password"
            postgresql:
              auth:
                postgresPassword: "bepis"
                password: "boopis"
              image:
                debug: true
              primary:
                extendedConfiguration: |-
                  huge_pages = off
                initdb:
                  args: "--set huge_pages=off"

            extraVolumes:
              - name: keycloak-theme-data
                persistentVolumeClaim:
                  claimName: keycloak-theme-pvc

            extraVolumeMounts:
              - name: keycloak-theme-data
                mountPath: /opt/bitnami/keycloak/providers
          EOT
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.keycloak.metadata[0].name
      }
      syncPolicy = {
        automated = {}
      }
    }
  }
}

resource "kubernetes_manifest" "vservice_keycloak_main" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name = "vservice-keycloak"
      namespace = kubernetes_namespace.keycloak.metadata[0].name
    }
    spec = {
      hosts = ["keycloak.tiny.pizza", "keycloak.dwbrite.com"]
      gateways = ["istio-system/dwbrite-com-gateway", "istio-system/tiny-pizza-gateway"]
      http = [
        {
          route = [
            {
              destination = {
                host = "keycloak"
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

