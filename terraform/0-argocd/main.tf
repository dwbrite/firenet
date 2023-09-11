# Create the namespace if it doesn't exist
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Install Argo CD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Ensure this is run after the namespace is created
  depends_on = [kubernetes_namespace.argocd]
}
