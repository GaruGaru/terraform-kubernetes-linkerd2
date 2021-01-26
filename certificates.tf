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

resource "kubernetes_manifest" "linkerd_certificate_issuer" {
  provider = "kubernetes-alpha"
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
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
  provider = "kubernetes-alpha"
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "linkerd-identity-issuer"
      "namespace" = kubernetes_namespace.linkerd.metadata.0.name
    }
    "spec" = {
      "commonName" = "identity.linkerd.cluster.local"
      "duration" = "24h"
      "isCA" = true
      "issuerRef" = {
        "kind" = "Issuer"
        "name" = kubernetes_manifest.linkerd_certificate_issuer.manifest.metadata.name
      }
      "keyAlgorithm" = "ecdsa"
      "renewBefore" = "1h"
      "secretName" = kubernetes_secret.ca-issuer-secret.metadata.0.name
      "usages" = [
        "cert sign",
        "crl sign",
        "server auth",
        "client auth",
      ]
    }
  }

}
