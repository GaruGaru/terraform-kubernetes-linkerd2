provider "helm" {
  version = "1.2.3"
  kubernetes {
    host                   = var.kubernetes.host
    cluster_ca_certificate = var.kubernetes.cluster_ca_certificate
    token                  = var.kubernetes.token
  }
}

provider "kubernetes-alpha" {
  host                   = var.kubernetes.host
  cluster_ca_certificate = var.kubernetes.cluster_ca_certificate
  token                  = var.kubernetes.token
}
