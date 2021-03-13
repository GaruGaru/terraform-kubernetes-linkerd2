resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = var.namespace
    labels = {
      "linkerd.io/admission-webhooks" : "disabled"
    }
  }
}

resource "helm_release" "linkerd2" {
  chart            = "linkerd2"
  repository       = var.helm_repository
  version          = var.linkerd_chart_version
  namespace        = kubernetes_namespace.linkerd.metadata.0.name
  name             = var.helm_release_name
  create_namespace = false

  values = coalesce([
    file("${path.module}/charts/linkerd2/values.yml"),
    file("${path.module}/charts/linkerd2/values-ha.yml"),
  ], var.helm_release_values)

  set {
    name  = "installNamespace"
    value = "false"
  }

  set {
    name  = "global.namespace"
    value = kubernetes_namespace.linkerd.metadata.0.name
  }

  // Certificates configuration
  set {
    name  = "global.identityTrustAnchorsPEM"
    value = tls_self_signed_cert.trustanchor_cert.cert_pem
  }

  set {
    name  = "identity.issuer.crtExpiry"
    value = tls_locally_signed_cert.issuer_cert.validity_end_time
  }

  set {
    name  = "identity.issuer.tls.crtPEM"
    value = tls_locally_signed_cert.issuer_cert.cert_pem
  }

  set {
    name  = "identity.issuer.tls.keyPEM"
    value = tls_private_key.issuer_key.private_key_pem
  }

  depends_on = [
    kubernetes_secret.ca-issuer-secret
  ]
}


resource "helm_release" "linkerd2-viz" {
  chart            = "linkerd2-viz"
  repository       = var.helm_repository
  version          = var.linkerd_chart_version
  namespace        = kubernetes_namespace.linkerd.metadata.0.name
  name             = "${var.helm_release_name}-viz"
  create_namespace = false

  values = coalesce([
    file("${path.module}/charts/linkerd-viz/values.yml"),
    file("${path.module}/charts/linkerd-viz/values-ha.yml"),
  ], var.helm_release_viz_values)

  set {
    name  = "installNamespace"
    value = "false"
  }

  set {
    name  = "linkerdNamespace"
    value = kubernetes_namespace.linkerd.metadata.0.name
  }

  set {
    name  = "linkerdNamespace"
    value = kubernetes_namespace.linkerd.metadata.0.name
  }

  depends_on = [
    kubernetes_secret.ca-issuer-secret
  ]
}

