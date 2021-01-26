# linkerd2-terraform

Deploy linkerd2 on kubernetes with ease !
This chart will deploy linkerd2 on a kubernetes cluster with custom trust anchor certificate and automatic certificate certificate rotation with cert-manager

## Usage

**!! cert-manager must be installed on the cluster !!**

```hcl
module "linkerd2" {
  source = "GaruGaru/linkerd2/kubernetes"
  version = "0.0.2"
  kubernetes {
    host: "...",
    cluster_ca_certificate: "...",
    token: "..."
  }

  trust_anchor_certificate_validity_period_hours = 87600 
}
```


