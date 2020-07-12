resource "null_resource" "apply" {
  count = var.enabled ? length(var.resources) : 0

  provisioner "local-exec" {
    command = "KUBECONFIG=${var.kubeconfig} kubectl apply -f ${var.resources[count.index]}"
  }

  triggers = {
    resources_hash = var.remote ? "remote" : sha1(file(var.resources[count.index]))
  }
}
