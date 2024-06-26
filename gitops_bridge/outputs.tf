
output "retrieve_creds" {
  description = "ArgoCD Access"
  value       = <<-EOT
    export KUBECONFIG="/tmp/${var.aws_cluster_name}"
    aws eks --region ${var.region} update-kubeconfig --name ${var.aws_cluster_name}
    echo "ArgoCD Username: admin"
    echo "ArgoCD Password: $(kubectl get secret argocd-secret -n argocd -o jsonpath="{.data.admin\.password}" | base64 --decode)"
    echo "Grafana Username: admin"
    echo "Grafana Password: $(kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)"
      
       # Retrieve the list of namespaces
    namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

    # Loop through each namespace
    for namespace in $namespaces; do
        echo "Namespace: $namespace"
        
        # Retrieve the list of Ingress resources in the current namespace
        ingresses=$(kubectl get ing -n "$namespace" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
        
        # Loop through each Ingress resource in the current namespace
        for ingress_name in $ingresses; do
            # Retrieve the URL associated with the current Ingress resource
            ingress_url=$(kubectl get ing -n "$namespace" "$ingress_name" -o jsonpath='{.spec.rules[0].host}')
            
            # Print the Ingress name and its associated URL
            echo "  $ingress_name URL: https://$ingress_url"
        done
    done
EOT
}

