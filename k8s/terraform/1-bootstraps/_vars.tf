variable "cloudflare-dns-token" {
  type = string
}

variable "email" {
  type    = string
}

variable "root_domain" {
  type    = string
}

variable "kubernetes_backend" {
  type = map
}
