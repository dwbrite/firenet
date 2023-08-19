resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_secret" "cloudflare-dns-token"{
  metadata {
    name = "cloudflare-dns-token"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
  }
  type = "Opaque"
  data = {
    api-token = var.cloudflare-dns-token
  }
}

resource "null_resource" "apply_cert_manager_crds" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.3/cert-manager.crds.yaml"
  }
}

resource "kubernetes_manifest" "cert-manager" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name = "cert-manager-app"
      namespace = "argocd" # TODO: template me from tf output
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/dwbrite/firenet.git"
        path           = "k8s/apps/cert-manager"
        targetRevision = "HEAD"
        helm = {
          values = <<-EOT
            destNamespace: cert-manager

            configApp:
              name: cert-manager-config
              namespace: argocd
              repoURL: https://github.com/dwbrite/firenet.git
              chartPath: k8s/apps/cert-manager/config
              clusterIssuer:
                name: letsencrypt-prod
                email: dwbrite@gmail.com
                acmeServer: https://acme-v02.api.letsencrypt.org/directory
                privateKeySecret: letsencrypt-prod-pkey
                cloudflareApiTokenSecret: cloudflare-dns-token

            certManagerApp:
              name: cert-manager
              namespace: argocd
              repoURL: https://charts.jetstack.io
              targetRevision: v1.12.3
              chartName: cert-manager
          EOT
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.cert-manager.metadata[0].name
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
