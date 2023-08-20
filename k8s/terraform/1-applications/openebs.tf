
resource "kubernetes_namespace" "openebs" {
  metadata {
    name = "openebs-system"
  }
}

resource "kubernetes_manifest" "openebs_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name = "openebs"
      namespace = "argocd" # TODO: template me from tf output
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/dwbrite/firenet.git"
        path           = "k8s/apps/openebs"
        targetRevision = "HEAD"
        helm = {}
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.openebs.metadata[0].name
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