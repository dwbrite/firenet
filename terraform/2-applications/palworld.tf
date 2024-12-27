resource "kubernetes_namespace" "palworld" {
  metadata {
    name = "palworld"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_manifest" "argocd_application_palworld" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "palworld-server"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://twinki14.github.io/palworld-server-chart"
        chart          = "palworld-server"
        targetRevision = "0.30.1"
        helm = {
          values = <<-EOF

          EOF
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.palworld.metadata[0].name
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

# resource "kubernetes_manifest" "vservice_palworld" {
#   manifest = {
#     apiVersion = "networking.istio.io/v1alpha3"
#     kind       = "VirtualService"
#     metadata = {
#       name      = "vservice-palworld"
#       namespace = kubernetes_namespace.palworld.metadata[0].name
#     }
#     spec = {
#       hosts = ["pals.dwbrite.com", "pals.tiny.pizza"]
#       gateways = ["istio-system/dwbrite-com-gateway", "istio-system/tiny-pizza-gateway"]
#       tcp = [
#         {
#           match = [
#             {
#               port = 8211
#             }
#           ]
#           route = [
#             {
#               destination = {
#                 host = "palworld-server-palworld"
#                 port = {
#                   number = 8211
#                 }
#               }
#             }
#           ]
#         }
#       ]
#     }
#   }
# }
