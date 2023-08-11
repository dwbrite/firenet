
resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb"
  }
}

resource "kubernetes_manifest" "metallb_helm" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "metallb-helm"
      namespace = "argocd" # TODO: template me from tf output
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://charts.bitnami.com/bitnami"
        targetRevision = "4.6.3"
        chart          = "metallb"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.metallb.metadata[0].name
      }
      syncPolicy = {
        automated = {}
      }
    }
  }
}

resource "kubernetes_manifest" "metallb_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name = "metallb-app"
      namespace = "argocd" # TODO: template me from tf output
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/dwbrite/firenet.git"
        path           = "k8s/apps/metallb"
        targetRevision = "HEAD"
        helm = {
          values = <<-EOT
            destNamespace: ${ kubernetes_namespace.metallb.metadata[0].name }

            configApp:
              name: metallb-config
              namespace: argocd # TODO: template me from tf output

              repoURL: https://github.com/dwbrite/firenet.git
              chartPath: k8s/apps/metallb/config

              ipAddressPool:
                name: lan-cluster-address
                addressRange: 10.11.1.80/28
              l2advertisement:
                name: lan-cluster-l2advert

            helmApp:
              name: metallb-helm
              namespace: argocd # TODO: template me from tf output
              repoURL: https://charts.bitnami.com/bitnami
              targetRevision: 4.6.3
              chartName: metallb
          EOT
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.metallb.metadata[0].name
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