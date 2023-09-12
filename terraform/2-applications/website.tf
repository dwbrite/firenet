
resource "kubernetes_namespace" "dwbrite-com" {
  metadata {
    name = "dwbrite-com"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_manifest" "blue_dwbrite_com_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name = "dwbrite-com"
      namespace = "argocd" # TODO: template me from tf output
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/dwbrite/firenet.git"
        path           = "k8s/apps/website-rs/overlays/blue"
        targetRevision = "HEAD"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.dwbrite-com.metadata[0].name
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

resource "kubernetes_manifest" "green_dwbrite_com_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name = "dwbrite-com"
      namespace = "argocd" # TODO: template me from tf output
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/dwbrite/firenet.git"
        path           = "k8s/apps/website-rs/overlays/green"
        targetRevision = "HEAD"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.dwbrite-com.metadata[0].name
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
