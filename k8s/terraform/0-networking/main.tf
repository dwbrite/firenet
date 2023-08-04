# Cluster networking ###################################################################################################

resource "kubernetes_manifest" "metallb_ip_pool" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind = "IPAddressPool"
    metadata = {
      name = "lan-cluster-address"
      namespace = "metallb"
    }
    spec = {
      addresses = ["10.11.1.80/28"] # TODO: grab this dynamically? maybe bring cue in?
    }
  }
}

resource "kubernetes_manifest" "metallb_l2_advertisement" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind = "L2Advertisement"
    metadata = {
      name = "example" # todo: change me?
      namespace = "metallb"
    }
  }
}


# Proxy networking #####################################################################################################

resource "kubernetes_namespace" "external-proxy" {
  metadata {
    name = "external-proxy"
  }
}

## permissions

resource "kubernetes_service_account" "ip-proxy" {
  metadata {
    name = "ip-watcher"
    namespace = kubernetes_namespace.external-proxy.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "ip-proxy-role" {
  metadata {
    name = "ip-proxy-role"
  }

  rule {
    api_groups = [""]
    resources = ["services"]
    verbs = ["get", "watch", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster_role_binding" {
  metadata {
    name = "ip-proxy-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.ip-proxy-role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.ip-proxy.metadata[0].name
    namespace = kubernetes_service_account.ip-proxy.metadata[0].namespace
  }
}

resource "kubernetes_secret" "ssh_key_secret" {
  metadata {
    name = "ssh-key-secret"
    namespace = kubernetes_namespace.external-proxy.metadata[0].name
  }

  data = {
    ssh-privatekey = file("~/.ssh/clementine.pk")
  }

  type = "Opaque"
}


data "template_file" "update_script" {
  template = file("files/update_proxy.py")
}

data "template_file" "script_requirements" {
  template = file("files/requirements.txt")
}

resource "kubernetes_config_map" "update_script" {
  metadata {
    name = "update-script"
    namespace = kubernetes_namespace.external-proxy.metadata[0].name
  }

  data = {
    "update_script.py" = data.template_file.update_script.rendered
    "requirements.txt" = data.template_file.script_requirements.rendered
  }
}

resource "kubernetes_pod" "update_nginx" {
  metadata {
    name = "update-nginx"
    namespace = kubernetes_namespace.external-proxy.metadata[0].name
  }

  spec {
    service_account_name = "ip-watcher"

    volume {
      name = "script"
      config_map {
        name = kubernetes_config_map.update_script.metadata[0].name
      }
    }

    container {
      name  = "update-nginx"
      image = "python:3.11"

      command = ["/bin/bash", "-c",
        "pip install -r /scripts/requirements.txt && python -u /scripts/update_script.py"]

      volume_mount {
        name       = "script"
        mount_path = "/scripts"
        read_only  = true
      }

      env {
        name = "KUBERNETES_SERVICE_HOST"
        value = "gateway"
      }

      env {
        name = "KUBERNETES_SERVICE_PORT"
        value = "6443"
      }
    }

    restart_policy = "OnFailure"
  }
}

