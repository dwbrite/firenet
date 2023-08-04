 ACME #################################################################################################################

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_secret" "cloudflare-dns-token"{
  metadata {
    name = "cloudflare-dns-token"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
  }
  type = "Opaque"
  data = {
    api-token = var.cloudflare-dns-token
  }
}

module "cert_manager" {
  depends_on = [kubernetes_secret.cloudflare-dns-token]
  source        = "terraform-iaac/cert-manager/kubernetes"
  create_namespace = false
  namespace_name = kubernetes_namespace.cert-manager.metadata[0].name

  cluster_issuer_email                   = "dwbrite@gmail.com"
  cluster_issuer_name                    = "letsencrypt-prod"
  cluster_issuer_private_key_secret_name = "letsencrypt-prod-pkey"

  solvers = [{
    dns01 = {
      cloudflare = {
        apiTokenSecretRef =  {
          name = "cloudflare-dns-token"
          key = "api-token"
        }
      }
    }
  }]
}

# Load Balancing  ######################################################################################################
# TODO: add namespace for load balancing?

resource "helm_release" "nginx_ingress_controller" {
  repository = "https://charts.bitnami.com/bitnami"
  name       = "nginx-ingress-controller"
  chart      = "nginx-ingress-controller"

  values = [ <<-EOT
    service:
      type: "LoadBalancer"
      extraPorts: [ { port: 8008, name: "matrix" }, { port: 8448, name: "matrix-ssl" } ]

    defaultBackend:
      enabled: false
    EOT
  ]
}

data "kubernetes_service" "nginx_ingress_data" {
  depends_on = [helm_release.nginx_ingress_controller]
  metadata {
    name = "nginx-ingress-controller"
  }
}

######### TEST BULLSHIT

resource "helm_release" "apache_it_works" {
  repository = "https://charts.bitnami.com/bitnami"
  name       = "apache"
  chart      = "apache"

  values = [ <<-EOT
    service:
      type: "ClusterIP"
    EOT
  ]
}

locals {
  host = var.root_domain
  cert_domain = var.root_domain
  cert_secret = "tls-root.${var.root_domain}"
  ingress_class = "nginx"
}

resource "kubernetes_ingress_v1" "ingress_rules" {
  metadata {
    name = "it-works-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/proxy-body-size": 0
      "cert-manager.io/cluster-issuer": "letsencrypt-prod"
      "kubernetes.io/ingress.class": local.ingress_class
    }
  }

  spec {
    rule {
      host = local.host
      http {
        path {
          path = "/"
          backend {
            service {
              name = "apache"
              port { number = 80 }
            }
          }
        }
      }
    }
    tls {
      hosts = [local.cert_domain]
      secret_name = local.cert_secret
    }
  }
}
