#  used ssh stored in secret manager and not local machine to emsure ability
# to use this infra code for both initial bootstrap and ability to run in k8s controller

locals {
  git_private_ssh_key = var.ssh_key_path # Update with the git ssh key to be used by ArgoCD
}
################################################################################
# GitOps Bridge: Private ssh keys for git
################################################################################
resource "kubernetes_namespace" "argocd" {
 metadata {
    name = "argocd"
  }
}

resource "kubernetes_secret" "git_secrets" {
  for_each = var.enable_git_ssh ? {
     git-workloads = {
       type          = "git"
       url =  "git@github.com:${var.git_owner}" 
       sshPrivateKey = var.cluster_bootstrap == "true" ? file(pathexpand(local.git_private_ssh_key)) : var.git_ssh_key
    }
  } : {}
  metadata {
    name      = each.key
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }
  data       = each.value
  depends_on = [kubernetes_namespace.argocd]
}

resource "kubernetes_secret_v1" "cluster" {

 metadata {
    name        = "in-cluster"
    namespace   = "argocd"
    annotations = local.argocd_annotations
    labels      = local.argocd_labels
  }
  data = {
      name   ="in-cluster"
      server = "https://kubernetes.default.svc"
      config = local.config
    }

  depends_on = [helm_release.argocd]
}

