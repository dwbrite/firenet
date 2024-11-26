resource "kubernetes_namespace" "openebs-system" {
  metadata {
    name = "openebs-system"
  }
}

locals {
  nodes_disks = [
#     { node="bernadette", disk="/dev/nvme0n1p3"}
    { node="nas", disk="/dev/nvme0n1p4"}
  ]

  disks_yml = join("", [
    "disks:\n",
    join("", [for disk in local.nodes_disks : "  - node: ${disk.node}\n    disk: ${disk.disk}\n"])
  ])
}

// Nodes _must_ be labelled with with:
// - storage-capable=true
// - openebs.tf.io/engine=mayastor

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
            mayastor: # as much as this looks like a typo...
              mayastor: # I promise it's not.
                nodeSelector:
                  storage-capable: "true"

              nodeSelector:
                storage-capable: "true"

              csi:
                node:
                  kubeletDir: /var/lib/k0s/kubelet

              image:
                repo: xin3liang
                tag: develop
                # repo: mayadata
                # tag: release-2.0
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

resource "kubernetes_manifest" "mayastor_diskpools" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "mayastor-diskpools"
      "namespace" = "argocd"
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "repoURL"        = "https://github.com/dwbrite/firenet.git"
        "targetRevision" = "HEAD"
        "path"           = "k8s/integrations/openebs/diskpools"
        "helm" = {
          "values" = local.disks_yml
        }
      }
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = kubernetes_namespace.openebs-system.metadata[0].name
      }
      "syncPolicy" = {
        "automated" = {}
      }
    }
  }
}
