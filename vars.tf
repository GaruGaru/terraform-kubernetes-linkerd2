variable "linkerd_version" {
  type = string
  default = "2.8.1"
}

variable "release_name" {
  type = string
  default = "linkerd"
}

variable "release_namespace" {
  type = string
  default = "linkerd"
}

variable "ha" {
  type = bool
  default = false
}

variable "linkerd_controller_image" {
  type = string
  default = "gcr.io/linkerd-io/controller"
}

variable "kube_config_path" {
  type = string
}

variable "trust_anchor_certificate_validity_period_hours" {
  type = number
  default = 87600 # 10 years
}

variable "issuer_certificate_validity_period_hours" {
  type = number
  default = 8760
}

variable "enable_grafana" {
  type = bool
  default = true
}

variable "enable_tracing" {
  type = bool
  default = true
}

variable "proxy_resource_request_cpu" {
  type = string
  default = null
}

variable "proxy_resource_limit_cpu" {
  type = string
  default = null
}

variable "proxy_resource_request_memory" {
  type = string
  default = null
}

variable "proxy_resource_limit_memory" {
  type = string
  default = null
}

variable "controller_resource_request_cpu" {
  type = string
  default = null
}

variable "controller_resource_limit_cpu" {
  type = string
  default = null
}

variable "controller_resource_request_memory" {
  type = string
  default = null
}

variable "controller_resource_limit_memory" {
  type = string
  default = null
}

variable "identity_resource_request_cpu" {
  type = string
  default = null
}

variable "identity_resource_limit_cpu" {
  type = string
  default = null
}

variable "identity_resource_request_memory" {
  type = string
  default = null
}

variable "identity_resource_limit_memory" {
  type = string
  default = null
}
