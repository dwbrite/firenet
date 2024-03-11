# Vars

variable "minio_root_user" {
  type = string
}

variable "minio_root_password" {
  type = string
}

# real shit

resource "kubernetes_namespace" "s3" {
  metadata {
    name = "s3"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_secret" "minio_creds" {
  metadata {
    name      = "minio-creds"
    namespace = kubernetes_namespace.s3.metadata[0].name
  }

  data = {
    root-user = var.minio_root_user
    root-password = var.minio_root_password
  }
}


resource "kubernetes_manifest" "minio-operator" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "minio-operator"
      namespace = "argocd" # TODO: PLEASE STOP HARD-CODING ME D;
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://operator.min.io/"
        targetRevision = "5.0.11"
        chart          = "operator"
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


// TODO: make services for tenants?
resource "kubernetes_manifest" "vservice_s3" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name = "vservice-s3"
      namespace = kubernetes_namespace.s3.metadata[0].name
    }
    spec = {
      hosts = ["s3.tiny.pizza", "s3.dwbrite.com"]
      gateways = ["istio-system/dwbrite-com-gateway", "istio-system/tiny-pizza-gateway"]
      http = [
        {
          route = [
            {
              destination = {
                host = "console"
                port = {
                  number = 9090
                }
              }
            }
          ]
        }
      ]
    }
  }
}


resource "kubernetes_manifest" "vservice_s3api" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name = "vservice-s3-api"
      namespace = kubernetes_namespace.s3.metadata[0].name
    }
    spec = {
      hosts = ["s3api.tiny.pizza", "s3api.dwbrite.com"]
      gateways = ["istio-system/dwbrite-com-gateway", "istio-system/tiny-pizza-gateway"]
      http = [
        {
          route = [
            {
              destination = {
                host = "minio"
                port = {
                  number = 9000
                }
              }
            }
          ]
        }
      ]
    }
  }
}
