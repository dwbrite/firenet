resource "kubernetes_namespace" "minecraft" {
  metadata {
    name = "minecraft"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_manifest" "argocd_application_minecraft" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "minecraft-server"
      namespace = "argocd" # Adjust if your ArgoCD namespace is different
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://itzg.github.io/minecraft-server-charts/"
        chart          = "minecraft"
        targetRevision = "4.23.6"
        helm = {
          values = <<-EOF
            minecraftServer:
              eula: "true"
              type: "VANILLA"
              version: "LATEST"
              memory: "4G"
              difficulty: "normal"
              maxPlayers: 50
              gameMode: "survival"
              motd: "Welcome to Devin's Minecraft server!"
              whitelist: "dwbrite,palgarten"
              ops: "dwbrite"

            persistence:
              dataDir:
                enabled: true
                Size: 20Gi
                accessModes:
                  - ReadWriteOnce

            resources:
              requests:
                memory: "4096Mi"
                cpu: "2000m"
          EOF
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.minecraft.metadata[0].name
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

resource "kubernetes_manifest" "vservice_minecraft" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name      = "vservice-minecraft"
      namespace = kubernetes_namespace.minecraft.metadata[0].name
    }
    spec = {
      hosts = ["minecraft.dwbrite.com", "minecraft.tiny.pizza"]
      gateways = ["istio-system/dwbrite-com-gateway", "istio-system/tiny-pizza-gateway"]
      tcp = [
        {
          match = [
            {
              port = 1337
            }
          ]
          route = [
            {
              destination = {
                host = "minecraft-server-minecraft"
                port = {
                  number = 25565
                }
              }
            }
          ]
        }
      ]
    }
  }
}



resource "kubernetes_manifest" "argocd_application_minecraft_ydb" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "minecraft-ydb-server"
      namespace = "argocd" # Adjust if your ArgoCD namespace is different
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://itzg.github.io/minecraft-server-charts/"
        chart          = "minecraft"
        targetRevision = "4.23.6"
        helm = {
          values = <<-EOF
            minecraftServer:
              eula: "true"
              type: "VANILLA"
              version: "LATEST"
              memory: "4G"
              difficulty: "normal"
              maxPlayers: 50
              gameMode: "survival"
              motd: "YA DUMB BITCH."
              ops: "dwbrite"

            persistence:
              dataDir:
                enabled: true
                Size: 20Gi
                accessModes:
                  - ReadWriteOnce

            resources:
              requests:
                memory: "4096Mi"
                cpu: "2000m"
          EOF
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.minecraft.metadata[0].name
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

resource "kubernetes_manifest" "vservice_minecraft_ydb" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name      = "vservice-minecraft-ydb"
      namespace = kubernetes_namespace.minecraft.metadata[0].name
    }
    spec = {
      hosts = ["mcydb.dwbrite.com", "mcydb.tiny.pizza"]
      gateways = ["istio-system/dwbrite-com-gateway", "istio-system/tiny-pizza-gateway"]
      tcp = [
        {
          match = [
            {
              port = 25565
            }

          ]
          route = [
            {
              destination = {
                host = "minecraft-ydb-server-minecraft"
                port = {
                  number = 25565
                }
              }
            }
          ]
        }
      ]
    }
  }
}
