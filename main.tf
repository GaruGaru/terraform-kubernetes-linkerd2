provider "helm" {
  version = "1.2.3"

  kubernetes {
    config_path = var.kube_config_path
  }
}

provider "kubernetes" {
  config_path = var.kube_config_path
}

locals {

  enablePodAntiAffinity = var.ha

  controller_replicas = var.ha ? coalesce(var.controller_replicas, 3) : coalesce(var.controller_replicas, 1)

  proxy_resource_request_cpu = var.ha ? coalesce(var.proxy_resource_request_cpu, "100m") : ""
  proxy_resource_limit_cpu = var.ha ? coalesce(var.proxy_resource_limit_cpu, "1") : ""

  proxy_resource_request_memory = var.ha ? coalesce(var.proxy_resource_request_memory, "20Mi") : ""
  proxy_resource_limit_memory = var.ha ? coalesce(var.proxy_resource_limit_memory, "250Mi") : ""


  controller_resource_request_cpu = var.ha ? coalesce(var.controller_resource_request_cpu, "100m") : ""
  controller_resource_limit_cpu = var.ha ? coalesce(var.controller_resource_limit_cpu, "1") : ""

  controller_resource_request_memory = var.ha ? coalesce(var.controller_resource_request_memory, "50Mi") : ""
  controller_resource_limit_memory = var.ha ? coalesce(var.controller_resource_limit_memory, "250Mi") : ""

  identity_resource_request_cpu = var.ha ? coalesce(var.identity_resource_request_cpu, "100m") : ""
  identity_resource_limit_cpu = var.ha ? coalesce(var.identity_resource_limit_cpu, "1") : ""

  identity_resource_request_memory = var.ha ? coalesce(var.identity_resource_request_memory, "10Mi") : ""
  identity_resource_limit_memory = var.ha ? coalesce(var.identity_resource_limit_memory, "250Mi") : ""

}

# source https://www.devopsfu.com/2020/01/17/automating-linkerd-installation-in-terraform/
resource "tls_private_key" "trustanchor_key" {
  algorithm = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "trustanchor_cert" {
  key_algorithm = tls_private_key.trustanchor_key.algorithm
  private_key_pem = tls_private_key.trustanchor_key.private_key_pem
  validity_period_hours = var.trust_anchor_certificate_validity_period_hours
  is_ca_certificate = true

  subject {
    common_name = "identity.linkerd.cluster.local"
  }

  allowed_uses = [
    "crl_signing",
    "cert_signing",
    "server_auth",
    "client_auth"
  ]
}
resource "tls_private_key" "issuer_key" {
  algorithm = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "issuer_req" {
  key_algorithm = tls_private_key.issuer_key.algorithm
  private_key_pem = tls_private_key.issuer_key.private_key_pem

  subject {
    common_name = "identity.linkerd.cluster.local"
  }
}

resource "tls_locally_signed_cert" "issuer_cert" {
  cert_request_pem = tls_cert_request.issuer_req.cert_request_pem
  ca_key_algorithm = tls_private_key.trustanchor_key.algorithm
  ca_private_key_pem = tls_private_key.trustanchor_key.private_key_pem
  ca_cert_pem = tls_self_signed_cert.trustanchor_cert.cert_pem
  validity_period_hours = var.issuer_certificate_validity_period_hours
  is_ca_certificate = true

  allowed_uses = [
    "crl_signing",
    "cert_signing",
    "server_auth",
    "client_auth"
  ]
}

resource "kubernetes_secret" "ca-issuer-secret" {
  metadata {
    name = "linkerd-identity-issuer"
    namespace = kubernetes_namespace.linkerd.metadata.0.name
  }

  type = "kubernetes.io/tls"

  data = {
    "ca.crt" = tls_self_signed_cert.trustanchor_cert.cert_pem
    "tls.crt" = tls_locally_signed_cert.issuer_cert.cert_pem
    "tls.key" = tls_private_key.issuer_key.private_key_pem
  }

}

resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = var.release_namespace
    labels = {
      "linkerd.io/admission-webhooks": "disabled"
    }
  }
}

resource "helm_release" "linkerd2" {

  chart = "linkerd2"
  repository = "linkerd2"
  version = var.linkerd_version
  namespace = kubernetes_namespace.linkerd.metadata.0.name
  name = var.release_name

  create_namespace = false
  set {
    name = "global.linkerdVersion"
    value = "stable-${var.linkerd_version}"
  }

  set {
    name = "installNamespace"
    value = "false"
  }

  set {
    name = "global.namespace"
    value = kubernetes_namespace.linkerd.metadata.0.name
  }

  set {
    name = "global.controllerImage"
    value = var.linkerd_controller_image
  }

  set {
    name = "global.grafana.enabled"
    value = var.enable_grafana
  }

  set {
    name = "global.tracing.enabled"
    value = var.enable_tracing
  }

  // Certificates configuration
  set {
    name = "global.identityTrustAnchorsPEM"
    value = tls_self_signed_cert.trustanchor_cert.cert_pem
  }

  set {
    name = "identity.issuer.crtExpiry"
    value = tls_locally_signed_cert.issuer_cert.validity_end_time
  }

  set {
    name = "identity.issuer.tls.crtPEM"
    value = tls_locally_signed_cert.issuer_cert.cert_pem
  }

  set {
    name = "identity.issuer.tls.keyPEM"
    value = tls_private_key.issuer_key.private_key_pem
  }

  // HA & Tuning

  set {
    name = "enablePodAntiAffinity"
    value = local.enablePodAntiAffinity
  }

  // Proxy configuration
  set {
    name = "global.proxy.resources.cpu.limit"
    value = local.proxy_resource_limit_cpu
  }

  set {
    name = "global.proxy.resources.cpu.request"
    value = local.proxy_resource_request_cpu
  }


  set {
    name = "global.proxy.resources.memory.limit"
    value = local.proxy_resource_limit_memory
  }

  set {
    name = "global.proxy.resources.memory.request"
    value = local.proxy_resource_request_memory
  }

  // Controller configuration

  set {
    name = "global.controllerReplicas"
    value = local.controller_replicas
  }

  set {
    name = "global.controllerResources.cpu.limit"
    value = local.controller_resource_limit_cpu
  }

  set {
    name = "global.controllerResources.cpu.request"
    value = local.controller_resource_request_cpu
  }

  set {
    name = "global.controllerResources.memory.limit"
    value = local.controller_resource_limit_memory
  }

  set {
    name = "global.controllerResources.memory.request"
    value = local.controller_resource_request_memory
  }

  // Identity configuration

  set {
    name = "global.identityResources.cpu.limit"
    value = local.identity_resource_limit_cpu
  }

  set {
    name = "global.identityResources.cpu.request"
    value = local.identity_resource_request_cpu
  }

  set {
    name = "global.identityResources.memory.limit"
    value = local.identity_resource_limit_memory
  }

  set {
    name = "global.identityResources.memory.request"
    value = local.identity_resource_request_memory
  }

  set {
    name = "identity.issuer.scheme"
    value = "kubernetes.io/tls"
  }

  // Grafana configuration
  // TODO

  // Prometheus configuration
  // TODO Wait for prometheus as addon release

  depends_on = [
    kubernetes_secret.ca-issuer-secret
  ]
}


// The official kubernetes provider doesn't support CRD creation so this ugly workaround is needed
// we have to wait for stable release of https://github.com/hashicorp/terraform-provider-kubernetes-alpha
module "cert-manager-linkerd-cert" {
  source = "./modules/k8s-apply"
  kubeconfig = var.kube_config_path
  remote = true
  resources = [
    local_file.linkerd-cert-issuer-crd.filename,
    local_file.linkerd-cert-crd.filename
  ]

  after = [
    kubernetes_secret.ca-issuer-secret.id
  ]
}


resource "local_file" "linkerd-cert-issuer-crd" {
  filename = "${path.module}/manifests/linkerd-cert-issuer.yml"
  content = templatefile("${path.module}/manifests/linkerd-cert-issuer.template.yml", {
    namespace = kubernetes_namespace.linkerd.metadata.0.name,
    secret = kubernetes_secret.ca-issuer-secret.metadata.0.name
  })
}

resource "local_file" "linkerd-cert-crd" {
  filename = "${path.module}/manifests/linkerd-cert.yml"
  content = templatefile("${path.module}/manifests/linkerd-cert.template.yml", {
    namespace = kubernetes_namespace.linkerd.metadata.0.name
  })
}

