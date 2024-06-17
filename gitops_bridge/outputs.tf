
output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = <<-EOT
    export KUBECONFIG="/tmp/${var.aws_cluster_name}"
    aws eks --region ${var.region} update-kubeconfig --name ${var.aws_cluster_name}
  EOT
}

output "configure_argocd" {
  description = "Terminal Setup"
  value       = <<-EOT
    export KUBECONFIG="/tmp/${var.aws_cluster_name}"
    aws eks --region ${var.region} update-kubeconfig --name ${var.aws_cluster_name}
    export ARGOCD_OPTS="--port-forward --port-forward-namespace argocd --grpc-web"
    kubectl config set-context --current --namespace argocd
    argocd login --port-forward --username admin --password $(aws secretsmanager get-secret-value --secret-id argocd --region ${var.region} --output json | jq -r .SecretString)
    echo "ArgoCD Username: admin"
    echo "ArgoCD Password: $(aws secretsmanager get-secret-value --secret-id argocd-${terraform.workspace} --region ${var.region} --output json | jq -r .SecretString)"
    echo Port Forward: http://localhost:8080
    kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:80
    EOT
}

output "access_argocd" {
  description = "ArgoCD Access"
  value       = <<-EOT
    export KUBECONFIG="/tmp/${var.aws_cluster_name}"
    aws eks --region ${var.region} update-kubeconfig --name ${var.aws_cluster_name}
    echo "ArgoCD Username: admin"
    echo "ArgoCD Password: $(aws secretsmanager get-secret-value --secret-id argocd-${terraform.workspace} --region ${var.region} --output json | jq -r .SecretString)"

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



