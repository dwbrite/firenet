resource "kubernetes_namespace" "openebs-system" {
  metadata {
    name = "openebs-system"
  }
}

// Nodes _must_ be labelled with with:
// - storage-capable=true
// - openebs.io/engine=mayastor

resource "kubernetes_manifest" "openebs_argocd_application" {
  provider = kubernetes

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "openebs"
      namespace = "argocd" # todo: don't harcode this pls I'm begging u
    }
    spec = {
      project = "default"
      source = {
        repoURL         = "https://github.com/dwbrite/openebs-charts.git"
        targetRevision  = "HEAD"
        path            = "charts/openebs"
        helm = {
          values = <<EOT
            mayastor:
              mayastor: # as much as this looks like a type, it's not.
                nodeSelector:
                  kubernetes.io/arch: arm64
                  storage-capable: "true"

              nodeSelector:
                kubernetes.io/arch: arm64
                storage-capable: "true"

              csi:
                node:
                  kubeletDir: /var/lib/k0s/kubelet

              image:
                repo: xin3liang
                tag: develop
              etcd:
                persistence:
                  enabled: false
                image:
                  repository: xin3liang/bitnami-etcd
                  tag: 3.5.1-debian-10-r67
                replicaCount: 1
                volumePermissions:
                  image:
                    repository: xin3liang/bitnami-shell
              loki-stack:
                enabled: false
              io_engine:
                nodeSelector:
                  kubernetes.io/arch: arm64
                  storage-capable: "true"
              enabled: true
          EOT
        }
      }
      destination = {
        namespace = kubernetes_namespace.openebs-system.metadata[0].name
        server    = "https://kubernetes.default.svc"
      }
      syncPolicy = {
        automated = {}
      }
    }
  }
}
