# COSI

resource "kubernetes_namespace" "cosi" {
  metadata {
    name = "cosi-system"
  }
}

resource "kubernetes_manifest" "cosi_api" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name = "cosi-api"
      namespace = "argocd" # TODO: PLEASE STOP HARD-CODING ME D;
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/kubernetes-sigs/container-object-storage-interface-api"
        targetRevision = "HEAD"  # TODO: don't specify at HEAD
        path = "./"
        kustomize      = {}
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.cosi.metadata[0].name
      }
      syncPolicy = {
        automated = {}  # Optional: for automatic sync
      }
    }
  }
}

resource "kubernetes_manifest" "cosi_controller" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name = "cosi-controller"
      namespace = "argocd" # TODO: PLEASE STOP HARD-CODING ME D;
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/kubernetes-sigs/container-object-storage-interface-controller"
        targetRevision = "HEAD"  # TODO: don't specify at HEAD
        path = "./"
        kustomize      = {}
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.cosi.metadata[0].name
      }
      syncPolicy = {
        automated = {}  # Optional: for automatic sync
      }
    }
  }
}

