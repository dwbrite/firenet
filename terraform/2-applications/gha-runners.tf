resource "kubernetes_namespace" "gha-website-rs-runner" {
  metadata {
    name = "github-actions-website-rs-runner"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_secret" "pre_defined_secret" {
  metadata {
    name      = "pre-defined-secret"
    namespace = kubernetes_namespace.gha-website-rs-runner.metadata[0].name
  }

  data = {
    github_token = var.github_pat
  }

  type = "Opaque"
}

resource "kubernetes_manifest" "argocd_application_runner" {
  provider = kubernetes

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "arc-runner-set"
      namespace = "argocd" # assuming you're using the default argocd namespace
    }
    spec = {
      destination = {
        namespace = kubernetes_namespace.gha-website-rs-runner.metadata[0].name
        server    = "https://kubernetes.default.svc"
      }
      project = "default"
      source = {
        repoURL        = "ghcr.io/actions/actions-runner-controller-charts"
        targetRevision = "0.5.0"
        helm = {
          values = <<-EOT
            githubConfigUrl: "https://github.com/dwbrite/website-rs"
            githubConfigSecret: "${ kubernetes_secret.pre_defined_secret.metadata[0].name }"
            containerMode:
              type: "dind"
            controllerServiceAccount:
              name: "github-arc-controller-gha-rs-controller"
              namespace: "github-actions"
          EOT
        }
        chart = "gha-runner-scale-set"
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

