
resource "kubernetes_namespace" "proxy" {
  metadata {
    name = "external-proxy"
  }
}

resource "kubernetes_secret" "proxy_server_ssh_key" {
  metadata {
    name = "proxy-server-ssh-key"
    namespace = kubernetes_namespace.proxy.metadata[0].name
  }

  data = {
    ssh-privatekey = file("~/.ssh/clementine.pk")
  }

  type = "Opaque"
}


resource "kubernetes_manifest" "proxy_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name = "proxy-app"
      namespace = "argocd" # TODO: template me from tf output
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/dwbrite/firenet.git"
        path           = "k8s/apps/proxy-networking"
        targetRevision = "HEAD"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.proxy.metadata[0].name
      }
      syncPolicy = {
        automated = {
          selfHeal = true
          prune    = true
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.proxy, kubernetes_secret.proxy_server_ssh_key]
}
