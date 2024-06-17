#!/bin/bash

set -uo pipefail

# Load variables from terraform.tfvars file
TF_VARS_FILE="terraform.tfvars"

# Function to extract variable from tfvars file
function get_tfvar {
  local var_name=$1
  grep -E "^${var_name}" ${TF_VARS_FILE} | cut -d'=' -f2 | tr -d '[:space:]' | tr -d '"'
}

# Extract variables from environment or tfvars
workspace=$(echo "${TF_VAR_workspace:-$(get_tfvar "workspace")}" | tr -d '\r')
region=$(echo "${TF_VAR_region:-$(get_tfvar "region")}" | tr -d '\r')
vpc_cidr=$(echo "${TF_VAR_vpc_cidr:-$(get_tfvar "vpc_cidr")}" | tr -d '\r')

# Function to check if an S3 bucket exists
check_s3_bucket_exists() {
  aws s3api head-bucket --bucket "$1" --region "$region" 2>/dev/null
}

# Function to check if a DynamoDB table exists
check_dynamodb_table_exists() {
  aws dynamodb describe-table --table-name "$1" --region "$region" 2>/dev/null
}

# Function to initialize and apply backend Terraform configuration
initialize_backend_bootstrap() {
  cd backend
  terraform init -reconfigure
  terraform apply -auto-approve
  cd ..
}

# Function to extract outputs from the backend configuration
extract_backend_outputs() {
  cd backend
  S3_BUCKET_NAME=$(terraform output -raw s3_bucket_name)
  DYNAMODB_NAME=$(terraform output -raw dynamodb_name)
  cd ..
}

# Function to check if VPC CIDR is already in use
function check_vpc_cidr {
  local cidr=$1
  local region=$2
  local vpcs_in_use=$(aws ec2 describe-vpcs --filters "Name=cidr,Values=${cidr}" --region ${region} --query "Vpcs[*].VpcId" --output text)

  if [ -n "$vpcs_in_use" ]; then
    echo "Error: VPC CIDR ${cidr} is already in use in region ${region}. Please use a different CIDR."
    exit 1
  else
    echo "VPC CIDR ${cidr} is available."
  fi
}

# Plan the backend configuration to get the bucket and table names
cd backend

terraform init -reconfigure -input=false
terraform plan -out=tfplan -input=false

# Extract the planned bucket and table names
PLANNED_S3_BUCKET_NAME=$(terraform show -json tfplan | jq -r '.planned_values.outputs.s3_bucket_name.value')
PLANNED_DYNAMODB_NAME=$(terraform show -json tfplan | jq -r '.planned_values.outputs.dynamodb_name.value')

cd ..

# Check if the S3 bucket and DynamoDB table exist
if check_s3_bucket_exists "$PLANNED_S3_BUCKET_NAME" && check_dynamodb_table_exists "$PLANNED_DYNAMODB_NAME"; then
  echo "S3 bucket and DynamoDB table already exist. Skipping creation."
  S3_BUCKET_NAME="$PLANNED_S3_BUCKET_NAME"
  DYNAMODB_NAME="$PLANNED_DYNAMODB_NAME"
else
  echo "S3 bucket or DynamoDB table does not exist. Creating..."
  initialize_backend_bootstrap
  extract_backend_outputs
fi

# Validate required variables
: "${workspace:?Need to set WORKSPACE in environment or terraform.tfvars}"
: "${region:?Need to set REGION in environment or terraform.tfvars}"
: "${vpc_cidr:?Need to set VPC_CIDR in environment or terraform.tfvars}"

# Check if the provided VPC CIDR is already in use
check_vpc_cidr "$vpc_cidr" "$region"

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

# Initialize Terraform configuration
terraform init -reconfigure

# Check if the workspace exists
if terraform workspace list | grep -q "$workspace"; then
    echo "Workspace $workspace exists."
    terraform workspace select "$workspace"
    export GODEBUG=asyncpreemptoff=1
    export TF_REGISTRY_CLIENT_TIMEOUT=20000

    if [[ -z "${TF_VAR_workspace}" || -z "${TF_VAR_region}" || -z "${TF_VAR_vpc_cidr}" ]]; then
        terraform apply -auto-approve -var-file=$TF_VARS_FILE
    else
        terraform apply -auto-approve
    fi
else
    echo "Deploying $workspace with $vpc_cidr vpc_cidr..."
    echo "Workspace $workspace does not exist. Creating..."

    terraform workspace new "$workspace"
    terraform workspace select "$workspace"
    export GODEBUG=asyncpreemptoff=1
    export TF_REGISTRY_CLIENT_TIMEOUT=20000

    if [[ -z "${TF_VAR_workspace}" || -z "${TF_VAR_region}" || -z "${TF_VAR_vpc_cidr}" ]]; then
        terraform apply -auto-approve -var-file=$TF_VARS_FILE
    else
        terraform apply -auto-approve
    fi
fi
