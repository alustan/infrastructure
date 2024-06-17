#!/bin/bash

set -uo pipefail

# Load variables from terraform.tfvars file
TF_VARS_FILE="terraform.tfvars"

# Function to extract variable from tfvars file
function get_tfvar {
  local var_name=$1
  grep -E "^${var_name}" ${TF_VARS_FILE} | cut -d'=' -f2 | xargs | tr -d '\r'
}

# Extract variables from environment or tfvars
workspace=$(echo "${TF_VAR_workspace:-$(get_tfvar "workspace")}" | tr -d '\r')
region=$(echo "${TF_VAR_region:-$(get_tfvar "region")}" | tr -d '\r')


# Plan the backend-bootstrap configuration to get the bucket and table names
cd backend

terraform init -reconfigure -input=false
terraform plan -out=tfplan -input=false

# Extract the planned bucket and table names
S3_BUCKET_NAME=$(terraform show -json tfplan | jq -r '.planned_values.outputs.s3_bucket_name.value')
DYNAMODB_NAME=$(terraform show -json tfplan | jq -r '.planned_values.outputs.dynamodb_name.value')

cd ..

# Validate required variables
: "${workspace:?Need to set WORKSPACE in environment or terraform.tfvars}"
: "${region:?Need to set REGION in environment or terraform.tfvars}"


# Write backend configuration to main Terraform configuration
cat > backend.tf <<EOL
terraform {
  backend "s3" {
    bucket         = "${S3_BUCKET_NAME}"
    key            = "${workspace}/${region}/terraform.tfstate"
    region         = "${region}"
    dynamodb_table = "${DYNAMODB_NAME}"
  }
}
EOL

set -e

echo "Destroying $workspace..."

# Initialize Terraform configuration
terraform init -reconfigure

# Select the workspace
terraform workspace select "$workspace"

export KUBECONFIG="/tmp/${workspace}-eks"
aws eks --region "${region}" update-kubeconfig --name "${workspace}-eks"

kubectl patch ns argocd --type json --patch='[ { "op": "remove", "path": "/spec/finalizers" } ]'

# Retrieve the list of namespaces
namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

# Loop through each namespace
for namespace in $namespaces; do
    echo "Namespace: $namespace"
    
    # Retrieve the list of Ingress resources in the current namespace
    ingresses=$(kubectl get ing -n "$namespace" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
    
    # Loop through each Ingress resource in the current namespace
    for ingress_name in $ingresses; do
        kubectl delete ing "$ingress_name" -n "$namespace"
    done
done

export GODEBUG=asyncpreemptoff=1
export TF_REGISTRY_CLIENT_TIMEOUT=20000

if [[  -z "${TF_VAR_workspace}" || -z "${TF_VAR_region}"  ]]; then
    terraform destroy -auto-approve -var-file=$TF_VARS_FILE
else
    terraform destroy -auto-approve
fi
