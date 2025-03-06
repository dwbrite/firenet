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

// TODO: fixme, this is never run??
resource "null_resource" "apply_cert_manager_crds" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml"
  }
}

resource "kubernetes_manifest" "cert-manager" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata"   = {
      "name"      = "cert-manager"
      "namespace" = "argocd"
    }
    "spec" = {
      "project" = "default"
      "source"  = {
        "repoURL"        = "https://charts.jetstack.io"
        "targetRevision" = "v1.17.1"
        "chart"          = "cert-manager"
      }
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = kubernetes_namespace.cert-manager.metadata[0].name
      }
      "syncPolicy" = {
        "automated" = {}
      }
    }
  }
}

resource "kubernetes_manifest" "cluster-issuer" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "cert-manager-cluster-issuer"
      "namespace" = "argocd"
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "repoURL"        = "https://github.com/dwbrite/firenet.git"
        "targetRevision" = "HEAD"
        "path"           = "k8s/integrations/cert-manager/cluster-issuer"
        "helm" = {
          "values" = <<-EOT
            namespace: ${kubernetes_namespace.cert-manager.metadata[0].name}

            clusterIssuer:
              name: letsencrypt-prod
              email: ${var.email}
              acmeServer: https://acme-v02.api.letsencrypt.org/directory
              privateKeySecret: letsencrypt-prod-pkey
              cloudflareApiTokenSecret: ${kubernetes_secret.cloudflare-dns-token.metadata[0].name}
          EOT
        }
      }
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = kubernetes_namespace.cert-manager.metadata[0].name
      }
      "syncPolicy" = {
        "automated" = {}
      }
    }
  }
}
