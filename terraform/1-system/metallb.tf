
resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb"
  }
}

resource "kubernetes_manifest" "metallb" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "metallb"
      "namespace" = "argocd"
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "repoURL"        = "https://charts.bitnami.com/bitnami"
        "targetRevision" = "4.6.3"
        "chart"          = "metallb"
      }
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = kubernetes_namespace.metallb.metadata[0].name
      }
      "syncPolicy" = {
        "automated" = {}
      }
      "ignoreDifferences" = [
        {
          "group" = "apiextensions.k8s.io"
          "kind" = "CustomResourceDefinition"
          "jsonPointers" = ["/spec/conversion/webhook/clientConfig/caBundle"]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "metallb-address-pool" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "metallb-address-pool"
      "namespace" = "argocd"
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "repoURL"        = "https://github.com/dwbrite/firenet.git"
        "targetRevision" = "HEAD"
        "path"           = "k8s/integrations/metallb/address-pool"
        "helm" = {
          "values" = <<-EOT
            ipAddressPool:
              name: lan-cluster-address
              addressRange: 10.11.1.80/28 # I think we actually want this to be /32

            l2advertisement:
              name: lan-cluster-l2advert
          EOT
        }
      }
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = kubernetes_namespace.metallb.metadata[0].name
      }
      "syncPolicy" = {
        "automated" = {}
      }
    }
  }
}
