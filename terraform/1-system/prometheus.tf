# Namespace for Prometheus stack
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# ArgoCD Application to deploy kube-prometheus-stack
resource "kubernetes_manifest" "kube_prometheus_stack" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "kube-prometheus-stack"
      "namespace" = "argocd"
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "repoURL"        = "https://prometheus-community.github.io/helm-charts"
        "targetRevision" = "v69.7.4" # Latest stable release
        "chart"          = "kube-prometheus-stack"
        "helm" = {
          "values" = <<-EOT
            prometheusOperator:
              nodeSelector:
                kubernetes.io/arch: amd64

            prometheus:
              prometheusSpec:
                nodeSelector:
                  kubernetes.io/arch: amd64
                retention: 10d
                storageSpec:
                  volumeClaimTemplate:
                    spec:
                      accessModes: ["ReadWriteOnce"]
                      resources:
                        requests:
                          storage: 20Gi

            grafana:
              enabled: true
              adminPassword: "admin" # Set a secure password
              service:
                type: ClusterIP

            alertmanager:
              enabled: false

            kubeApiServer:
              enabled: true

            kubelet:
              enabled: true

            kubeControllerManager:
              enabled: true

            kubeScheduler:
              enabled: true

            kubeEtcd:
              enabled: false
          EOT
        }
      }
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = kubernetes_namespace.monitoring.metadata[0].name
      }
      "syncPolicy" = {
        "automated" = {}
      }
    }
  }
}
