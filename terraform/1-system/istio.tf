resource "kubernetes_namespace" "istio" {
  metadata {
    name = "istio-system"
  }
}

resource "kubernetes_manifest" "istio_base" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "istio-base"
      namespace = "argocd" # TODO: PLEASE STOP HARD-CODING ME D;
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://istio-release.storage.googleapis.com/charts"
        targetRevision = "1.20.3"
        chart          = "base"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.istio.metadata[0].name
      }
      syncPolicy = {
        automated = {}
      }
    }
  }
}

resource "kubernetes_manifest" "istio_istiod" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "istio-istiod"
      namespace = "argocd" # TODO: PLEASE STOP HARD-CODING ME D;
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://istio-release.storage.googleapis.com/charts"
        targetRevision = "1.20.3"
        chart          = "istiod"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.istio.metadata[0].name
      }
      syncPolicy = {
        automated = {}
      }
    }
  }
}

resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "istio-system" # Adjust to match the namespace of your Prometheus deployment
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "prometheus" # Make sure this matches the labels on your Prometheus pods
    }

    port {
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
      name        = "http"
    }
  }
}


resource "kubernetes_manifest" "istio_ingress_gateway" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "istio-ingress-gateway"
      namespace = "argocd" # TODO: PLEASE STOP HARD-CODING ME D;
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://istio-release.storage.googleapis.com/charts"
        targetRevision = "1.20.3"
        chart          = "gateway"
        helm = {
          values = <<-EOF
            service:
              type: LoadBalancer
              ports:
                - name: status-port
                  port: 15021
                  protocol: TCP
                  targetPort: 15021
                - name: http2
                  port: 80
                  protocol: TCP
                  targetPort: 80
                - name: https
                  port: 443
                  protocol: TCP
                  targetPort: 443
                - name: minio-api
                  port: 9000
                  protocol: TCP
                  targetPort: 9000
          EOF
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.istio.metadata[0].name
      }
      syncPolicy = {
        automated = {}
      }
    }
  }
}


resource "kubernetes_manifest" "istio_kiali" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "istio-kiali"
      namespace = "argocd" # TODO: PLEASE STOP HARD-CODING ME D;
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://kiali.org/helm-charts"
        targetRevision = "1.77"
        chart          = "kiali-server"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.istio.metadata[0].name
      }
      syncPolicy = {
        automated = {}
      }
    }
  }
}



