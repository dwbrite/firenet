
resource "kubernetes_namespace" "garage" {
  metadata {
    name = "garage"

    labels = {}
  }
}

resource "kubernetes_manifest" "garage" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name = "garage"
      namespace = "argocd" # TODO: template me from tf output
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://git.deuxfleurs.fr/Deuxfleurs/garage"
        path           = "script/helm/garage"
        targetRevision = "v0.8.2"
        helm = {}
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.garage.metadata[0].name
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
