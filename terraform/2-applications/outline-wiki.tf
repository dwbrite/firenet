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


# real shit

resource "kubernetes_namespace" "outline-wiki" {
  metadata {
    name = "outline-wiki"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_secret" "outline_creds" {
  metadata {
    name      = "outline-creds"
    namespace = kubernetes_namespace.outline-wiki.metadata[0].name
  }

  data = {
    username = var.keycloak_admin_username
    password = var.keycloak_admin_password
  }
}

resource "kubernetes_secret" "outline_creds" {
  metadata {
    name      = "minio-creds"
    namespace = kubernetes_namespace.outline-wiki.metadata[0].name
  }

  data = {
    username = var.keycloak_admin_username
    password = var.keycloak_admin_password
  }
}

// add DEPENDS_ON keycloak


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

