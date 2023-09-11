
resource "kubernetes_namespace" "github-actions" {
  metadata {
    name = "github-actions"
  }
}

resource "kubernetes_manifest" "arc_controller" {
  provider = kubernetes

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "github-arc-controller"
      namespace = "argocd" # assuming you're using the default argocd namespace
    }
    spec = {
      destination = {
        namespace = kubernetes_namespace.github-actions.metadata[0].name # Installing in default namespace. Change if required.
        server    = "https://kubernetes.default.svc"
      }
      project = "default" # assuming you're using the default project
      source = {
        repoURL        = "ghcr.io/actions/actions-runner-controller-charts"
        targetRevision = "0.5.0"
        helm = {}
        chart = "gha-runner-scale-set-controller"
      }
      syncPolicy = {
        automated = {
          prune     = true
          selfHeal  = true
        }
      }
    }
  }
}




