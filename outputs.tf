output "configure_kubectl" {
  description = "configure kubectl"
  value       = local.configure_kubectl
}

output "configure_argocd" {
  description = "configure argocd"
  value       = local.configure_argocd
}

output "retrieve_creds" {
  description = "access argocd"
  value       = local.access_argocd
}