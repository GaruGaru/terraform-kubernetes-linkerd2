variable "linkerd_version" {
  type = string
  default = "2.8.1"
  description = "linkerd release version"
}

variable "release_name" {
  type = string
  default = "linkerd"
  description = "helm release name"
}

variable "release_namespace" {
  type = string
  default = "linkerd"
  description = "linkerd namespace"
}

variable "ha" {
  type = bool
  default = false
  description = "enable HA mode (for production environments)"
}

variable "linkerd_controller_image" {
  type = string
  default = "gcr.io/linkerd-io/controller"
  description = "linkerd controller image"
}

variable "kube_config_path" {
  type = string
  description = "kubeconfig path for cluster connection"
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

variable "enable_grafana" {
  type = bool
  default = true
  description = "deploy and configure grafana"
}

variable "enable_tracing" {
  type = bool
  default = true
  description = "deploy and configure tracing stack (jager with opencensus collector)"
}

variable "proxy_resource_request_cpu" {
  type = string
  default = null
  description = "proxy resource cpu request (if not set no request will be set, in HA mode the suggested values from the doc will be used)"
}

variable "proxy_resource_limit_cpu" {
  type = string
  default = null
  description = "proxy resource cpu limit (if not set no limit will be set, in HA mode the suggested values from the doc will be used)"
}

variable "proxy_resource_request_memory" {
  type = string
  default = null
  description = "proxy resource memory request (if not set no request will be set, in HA mode the suggested values from the doc will be used)"
}

variable "proxy_resource_limit_memory" {
  type = string
  default = null
  description = "proxy resource memory limit (if not set no limit will be set, in HA mode the suggested values from the doc will be used)"
}

variable "controller_resource_request_cpu" {
  type = string
  default = null
  description = "controller resource cpu request (if not set no request will be set, in HA mode the suggested values from the doc will be used)"
}

variable "controller_resource_limit_cpu" {
  type = string
  default = null
  description = "controller resource cpu limit (if not set no limit will be set, in HA mode the suggested values from the doc will be used)"
}

variable "controller_resource_request_memory" {
  type = string
  default = null
  description = "controller resource memory request (if not set no request will be set, in HA mode the suggested values from the doc will be used)"
}

variable "controller_resource_limit_memory" {
  type = string
  default = null
  description = "controller resource memory limit (if not set no limit will be set, in HA mode the suggested values from the doc will be used)"
}

variable "identity_resource_request_cpu" {
  type = string
  default = null
  description = "identity resource cpu request (if not set no request will be set, in HA mode the suggested values from the doc will be used)"
}

variable "identity_resource_limit_cpu" {
  type = string
  default = null
  description = "identity resource cpu limit (if not set no limit will be set, in HA mode the suggested values from the doc will be used)"
}

variable "identity_resource_request_memory" {
  type = string
  default = null
  description = "identity resource memory request (if not set no request will be set, in HA mode the suggested values from the doc will be used)"
}

variable "identity_resource_limit_memory" {
  type = string
  default = null
  description = "identity resource memory limit (if not set no limit will be set, in HA mode the suggested values from the doc will be used)"
}
