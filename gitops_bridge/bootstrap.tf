################################################################################
# GitOps Bridge: Bootstrap for Addons
################################################################################
resource "argocd_application" "bootstrap_addons" {

  metadata {
    name      = "bootstrap-addons"
    namespace = "argocd"
    labels = {
      cluster = "in-cluster"
    }
  }
  cascade = true
  wait    = true
  spec {
    project = "default"
    destination {
      name      = "in-cluster"
      namespace = "argocd"
    }
    source {
      repo_url        = "${local.github_url}/${var.addons_git_repo}"
      path            =  var.addons_repo_path
      target_revision = var.addons_git_revision
      directory {
        recurse = true
        }
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }
    }
  }
  depends_on = [helm_release.argocd]
}


################################################################################
# GitOps Bridge: Bootstrap for Workloads
################################################################################
resource "argocd_application" "bootstrap_workload" {
  metadata {
    name      = "bootstrap-workload"
    namespace = "argocd"
    labels = {
      cluster = "in-cluster"
    }
  }

  cascade = true
  wait    = true

  spec {
    project = "default"
    destination {
      name      = "in-cluster"
      namespace = "argocd"
    }
    source {
      repo_url        = "${local.github_url}/${var.workload_git_repo}"
      path            = "${var.workload_repo_path}/${var.cluster_bootstrap ? "infrastructure" : "applications"}/${terraform.workspace}"
      target_revision = var.workload_git_revision
      directory {
        recurse = true
      }
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }
    }
  }

  depends_on = [helm_release.argocd, argocd_application.bootstrap_addons]
}
