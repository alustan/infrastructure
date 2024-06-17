#!/bin/bash

set -e



function install_terraform() {
wget https://releases.hashicorp.com/terraform/1.8.1/terraform_1.8.1_linux_amd64.zip && \
    unzip terraform_1.8.1_linux_amd64.zip -d /usr/local/bin/ && \
    rm terraform_1.8.1_linux_amd64.zip
}

function install_kubectl() {
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl
}


function get_valid_input() {
    local placeholder=$1
    local is_password=${2:-false}  # Default is_password to false if not provided
    local user_input=""
    local valid_input=false

    while [ "$valid_input" = false ]; do
        if [ "$is_password" = true ]; then
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

##########################################################################################################

###########################################################################################################



# Check if Gum is installed
if ! command -v gum &> /dev/null; then
    echo "Gum not found. Installing..." 
    echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install gum
fi


gum style \
	--foreground 212 --border-foreground 212 --border double \
	--margin "1 2" --padding "2 4" \
	'installs and setups the necessary tools 
needed to bootstrap the control cluster '

gum confirm '
Are you ready to install and setup the needed tools?
    ' || exit 0

##########################################################################################################

###########################################################################################################


if ! command -v curl &> /dev/null; then
  echo "Curl is not installed. Installing..."
 apt-get install curl -y

fi

if ! command -v wget &> /dev/null; then
  echo "wget is not installed. Installing..."
 apt-get install wget -y

fi

if ! command -v unzip &> /dev/null; then
  echo "unzip is not installed. Installing..."
 apt-get install unzip -y

fi

if ! command -v terraform &> /dev/null; then
  echo "Terraform is not installed. Installing..."
  install_terraform

fi

if ! command -v kubectl &> /dev/null; then
  echo "Kubectl is not installed. Installing..."
  install_kubectl

fi


##########################################################################################################

###########################################################################################################


while true; do
    echo "Enter the provider (only AWS is currently supported):"
    CLOUD_PROVIDER=$(gum choose "google" "aws" "azure")

    if [[ "$CLOUD_PROVIDER" == "aws" ]]; then
        break
    else
        gum style \
    --foreground 212 --border-foreground 212 --border double \
    --margin "1 2" --padding "2 4" \
    'Provider is currently not supported. 
Only AWS is supported at the moment.'
        gum confirm "Do you wish to choose again? (yes/no)" || exit 0
    fi
done

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
        echo "Please enter region"
        REGION=$(get_valid_input "Enter AWS Region:")
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


gum style \
	--foreground 212 --border-foreground 212 --border double \
	--margin "1 2" --padding "2 4" \
	'                            Setup is ready!
---------------------------------------------------------------------------------   
...............................Happy provisioning................................'


