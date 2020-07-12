variable "kubeconfig" {
  type = string
}

variable "resources" {
  type = list(string)
}

variable "remote" {
  type = bool
  default = false
}

variable "after" {
  type = list
  default = []
}

variable "enabled" {
  type = bool
  default = true
}
