// TODO: create openebs namespace, create Application from help chart:
//  - helm install openebs --namespace openebs openebs/openebs --set engines.replicated.mayastor.enabled=false --create-namespace
//  set openebs-hostpath to default
//  cry, and one day re-enable openebs

resource "kubernetes_namespace" "openebs-system" {
  metadata {
    name = "openebs-system"
  }
}

resource "kubernetes_manifest" "openebs" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "openebs"
      "namespace" = "argocd"
    }
    "spec" = {
      "project" = "default"

      "source" = {
        "repoURL" = "https://openebs.github.io/openebs"
        "chart"   = "openebs"
        "targetRevision" = "4.1.1"
        "helm" = {
          "valueFiles" = []
          "parameters" = [
            {
              "name"  = "engines.replicated.mayastor.enabled"
              "value" = "false"
            }
          ]
        }
      }

      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = kubernetes_namespace.openebs-system.metadata[0].name
      }

      "syncPolicy" = {
        "automated" = {
          "prune" = true
          "selfHeal" = true
        }
      }
    }
  }
}

resource "null_resource" "patch_openebs_hostpath" {
  depends_on = [kubernetes_manifest.openebs]
  provisioner "local-exec" {
    command = "kubectl patch storageclass openebs-hostpath -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'"
  }
}
