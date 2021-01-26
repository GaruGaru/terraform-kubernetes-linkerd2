variable "kubernetes" {
  type = object({
    host: string,
    cluster_ca_certificate: string,
    token: string,
  })
}

variable "namespace" {
  type = string
  default = "linkerd"
}

variable "helm_repository" {
  type = string
  default = "https://helm.linkerd.io/stable"
}

variable "helm_release_name" {
  type = string
  default = "linkerd"
}

variable "linkerd_version" {
  type = string
  default = "2.9.2"
}

variable "trust_anchor_certificate_validity_period_hours" {
  type = number
  default = 87600
  # 10 years
  description = "duration for the trust anchor certificate in hours (the certificate must be rotated manually after the expiration)"
}

variable "issuer_certificate_validity_period_hours" {
  type = number
  default = 8760
  description = "duration for the issuer certificate in hours (the certificate will be rotated by cert-manager after the expiration)"
}
