provider "helm" {
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
  version = "2.0.2"
}
