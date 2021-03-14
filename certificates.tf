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

resource "tls_private_key" "issuer" {
  algorithm = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_private_key" "webhook" {
  algorithm = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "issuer" {
  key_algorithm = tls_private_key.issuer.algorithm
  private_key_pem = tls_private_key.issuer.private_key_pem

  subject {
    common_name = "identity.linkerd.cluster.local"
  }
}

resource "tls_cert_request" "webhook" {
  key_algorithm = tls_private_key.webhook.algorithm
  private_key_pem = tls_private_key.webhook.private_key_pem

  subject {
    common_name = "webhook.linkerd.cluster.local"
  }
}


resource "tls_locally_signed_cert" "issuer" {
  cert_request_pem = tls_cert_request.issuer.cert_request_pem
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

resource "tls_locally_signed_cert" "webhook" {
  cert_request_pem = tls_cert_request.webhook.cert_request_pem
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


resource "kubernetes_manifest" "linkerd_certificate_issuer" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Issuer"
    "metadata" = {
      "name" = "linkerd-trust-anchor"
      "namespace" = kubernetes_namespace.linkerd.metadata.0.name
    }
    "spec" = {
      "ca" = {
        "secretName" = "linkerd-trust-anchor"
      }
    }
  }
}


resource "kubernetes_manifest" "linkerd_certificate" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "linkerd-identity-issuer"
      "namespace" = kubernetes_namespace.linkerd.metadata.0.name
    }
    "spec" = {
      "commonName" = "identity.linkerd.cluster.local"
      "dnsNames": [
        "identity.linkerd.cluster.local"
      ]
      "duration" = "48h"
      "isCA" = true
      "issuerRef" = {
        "kind" = "Issuer"
        "name" = kubernetes_manifest.linkerd_certificate_issuer.manifest.metadata.name
      }
      "keyAlgorithm" = "ecdsa"
      "renewBefore" = "25h"
      "secretName" = "linkerd-identity-issuer"
      "usages" = [
        "cert sign",
        "crl sign",
        "server auth",
        "client auth",
      ]
    }
  }
}


resource "kubernetes_secret" "webhook-cert" {
  metadata {
    name = "webhook-issuer-tls"
    namespace = kubernetes_namespace.linkerd.metadata.0.name
  }

  type = "kubernetes.io/tls"

  data = {
    "ca.crt" = tls_self_signed_cert.trustanchor_cert.cert_pem
    "tls.crt" = tls_locally_signed_cert.webhook.cert_pem
    "tls.key" = tls_private_key.webhook.private_key_pem
  }
}

resource "kubernetes_manifest" "linkerd_webhook_certificate_issuer" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Issuer"
    "metadata" = {
      "name" = "webhook-issuer"
      "namespace" = kubernetes_namespace.linkerd.metadata.0.name
    }
    "spec" = {
      "ca" = {
        "secretName" = kubernetes_secret.webhook-cert.metadata.0.name
      }
    }
  }
}

resource "kubernetes_manifest" "linkerd_proxy_certificate" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "linkerd-proxy-injector"
      "namespace" = kubernetes_namespace.linkerd.metadata.0.name
    }
    "spec" = {
      "commonName" = "linkerd-proxy-injector.linkerd.svc"
      "dnsNames": ["linkerd-proxy-injector.linkerd.svc"]
      "duration" = "24h"
      "isCA" = false
      "issuerRef" = {
        "kind" = "Issuer"
        "name" = kubernetes_manifest.linkerd_webhook_certificate_issuer.manifest.metadata.name
      }
      "keyAlgorithm" = "ecdsa"
      "renewBefore" = "1h"
      "secretName" = "linkerd-proxy-injector-k8s-tls"
      "usages" = [
        "server auth",
      ]
    }
  }
}

resource "kubernetes_manifest" "linkerd_validator_certificate" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "linkerd-sp-validator"
      "namespace" = kubernetes_namespace.linkerd.metadata.0.name
    }
    "spec" = {
      "commonName" = "linkerd-sp-validator.linkerd.svc"
      "dnsNames": ["linkerd-sp-validator.linkerd.svc"]
      "duration" = "24h"
      "isCA" = false
      "issuerRef" = {
        "kind" = "Issuer"
        "name" = kubernetes_manifest.linkerd_webhook_certificate_issuer.manifest.metadata.name
      }
      "keyAlgorithm" = "ecdsa"
      "renewBefore" = "1h"
      "secretName" = "linkerd-sp-validator-k8s-tls"
      "usages" = [
        "server auth",
      ]
    }
  }
}

resource "kubernetes_manifest" "linkerd_tap_certificate" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "tap"
      "namespace" = kubernetes_namespace.linkerd.metadata.0.name
    }
    "spec" = {
      "commonName" = "tap.linkerd.svc"
      "dnsNames": ["tap.linkerd.svc"]
      "duration" = "24h"
      "isCA" = false
      "issuerRef" = {
        "kind" = "Issuer"
        "name" = kubernetes_manifest.linkerd_webhook_certificate_issuer.manifest.metadata.name
      }
      "keyAlgorithm" = "ecdsa"
      "renewBefore" = "1h"
      "secretName" = "tap-k8s-tls"
      "usages" = [
        "server auth",
      ]
    }
  }
}

resource "kubernetes_manifest" "linkerd_tap_injector_certificate" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "linkerd-tap-injector"
      "namespace" = kubernetes_namespace.linkerd.metadata.0.name
    }
    "spec" = {
      "commonName" = "tap-injector.linkerd.svc"
      "dnsNames": ["tap-injector.linkerd.svc"]
      "duration" = "24h"
      "isCA" = false
      "issuerRef" = {
        "kind" = "Issuer"
        "name" = kubernetes_manifest.linkerd_webhook_certificate_issuer.manifest.metadata.name
      }
      "keyAlgorithm" = "ecdsa"
      "renewBefore" = "1h"
      "secretName" = "tap-injector-k8s-tls"
      "usages" = [
        "server auth",
      ]
    }
  }
}

resource "kubernetes_manifest" "linkerd_jaeger_injector_certificate" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "jaeger-injector"
      "namespace" = kubernetes_namespace.linkerd.metadata.0.name
    }
    "spec" = {
      "commonName" = "jaeger-injector.linkerd.svc"
      "dnsNames": ["jaeger-injector.linkerd.svc"]
      "duration" = "24h"
      "isCA" = false
      "issuerRef" = {
        "kind" = "Issuer"
        "name" = kubernetes_manifest.linkerd_webhook_certificate_issuer.manifest.metadata.name
      }
      "keyAlgorithm" = "ecdsa"
      "renewBefore" = "1h"
      "secretName" = "jaeger-injector-k8s-tls"
      "usages" = [
        "server auth",
      ]
    }
  }
}
