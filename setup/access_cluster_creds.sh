  
#!/bin/bash

set -e

function get_valid_input() {
    local placeholder=$1
    local is_password=${2:-false}  # Default is_password to false if not provided
    local input_mode=${3:-input}   # Default to input if not provided
    local user_input=""
    local valid_input=false

    while [ "$valid_input" = false ]; do
        if [ "$input_mode" = "write" ]; then
            user_input=$(gum write --placeholder "$placeholder")
        elif [ "$is_password" = true ]; then
            user_input=$(gum input --placeholder "$placeholder" --password)
        else
            user_input=$(gum input --placeholder "$placeholder")
        fi

        if [[ ${#user_input} -gt 2 ]]; then
            valid_input=true
        fi
    done

    echo "$user_input"
}


function retrieve_control_cluster_data() {
    export KUBECONFIG="/tmp/${CLUSTER_NAME}"
    aws eks --region ${REGION} update-kubeconfig --name ${CLUSTER_NAME}
    
    # Retrieve the list of namespaces
    namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

    # Initialize the message with static parts
    message="ArgoCD Username: admin
ArgoCD Password: $(kubectl get secret argocd-secret -n argocd -o jsonpath="{.data.admin\.password}" | base64 --decode)
Grafana Username: admin
Grafana Password: $(kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
"

    # Loop through each namespace
    for namespace in $namespaces; do
        # Retrieve the list of Ingress resources in the current namespace
        ingresses=$(kubectl get ing -n "$namespace" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
        
        # Loop through each Ingress resource in the current namespace
        for ingress_name in $ingresses; do
            # Retrieve the URL associated with the current Ingress resource
            ingress_url=$(kubectl get ing -n "$namespace" "$ingress_name" -o jsonpath='{.spec.rules[0].host}')
            
            # Append the Ingress name and its associated URL to the message
            message+="Namespace: $namespace\n  $ingress_name URL: https://$ingress_url\n"
        done
    done

    # Display the message using gum style
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --margin "1 2" --padding "2 4" \
        "$message"
}

function install_kubectl() {
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

}

function installGum() {
echo "Gum not found. Installing..." 
echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum

}


# Check if Gum is installed
if ! command -v gum &> /dev/null; then
  installGum 
fi

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--margin "1 2" --padding "2 4" \
	'Retreieve cluster credentials
Cluster name and Region will be required'


gum confirm '
Do you wish to retreieve cluster credentials?
    ' || exit 0

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Installing curl..." 
    sudo apt install -y curl
fi

if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Installing..."
    install_kubectl
fi



##########################################################################################################

###########################################################################################################


echo "Provide cluster name" && \
  CLUSTER_NAME=$(get_valid_input "Please Provide cluster name:")

echo "Please enter region"
REGION=$(get_valid_input "Enter AWS Region:")

gum spin --spinner dot --title "Checking AWS CLI..." -- sleep 5 &

# Check if AWS CLI is installed and install if not
install_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI not found. Installing..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        sudo apt install -y unzip
        unzip awscliv2.zip
        sudo ./aws/install
    fi
}

# Check if AWS CLI is configured and configure if not
configure_aws_cli() {
   if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS CLI not configured. Configuring..." 
    echo "Please enter aws access key"
    ACCESS_KEY=$(get_valid_input "Enter AWS Access Key ID:")
    echo "Enter aws secret key"
    SECRET_KEY=$(get_valid_input "Enter AWS Secret Access Key:" true) 
    aws configure set aws_access_key_id "$ACCESS_KEY"
    aws configure set aws_secret_access_key "$SECRET_KEY"
    aws configure set region "$REGION"
fi
}

# Run the checks in the background
install_aws_cli &
configure_aws_cli &

# Wait for all background processes to complete
wait


retrieve_control_cluster_data

