#!/bin/bash

set -e

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

# Check if Gum is installed
if ! command -v gum &> /dev/null; then
    echo "Gum not found. Installing..."
    echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install gum
fi


##########################################################################################################

###########################################################################################################

gum style \
    --foreground 212 --border-foreground 212 --border double \
    --margin "1 2" --padding "2 4" \
    'Create and store secrets in AWS secret manager'

gum confirm '
Are you ready to create/store secrets?
    ' || exit 0


##########################################################################################################

###########################################################################################################

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Installing curl..." | gum format
    sudo apt install -y curl
fi

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

echo "Please enter name of AWS Secret store:"
SECRET_STORE_NAME=$(get_valid_input "Enter name of AWS Secret store:")


gum confirm "Do you wish to store secrets in AWS secret manager? (Choose NO if you want to just create secret store)" && {
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --margin "1 2" --padding "2 4" \
        'Please enter Secret keys and corresponding values'

    secret_string="{"
    first_pair=true

    # Prompt for the first secret key-value pair
    echo "Please enter AWS Secret key:"
    SECRET_NAME=$(get_valid_input "Enter AWS Secret key:")
   

    echo "Please enter corresponding secret value:"
    SECRET_VALUE=$(get_valid_input "Enter corresponding secret value" true)
    

    secret_string+="\"$SECRET_NAME\": \"$SECRET_VALUE\""
    first_pair=false

    # Prompt for additional key-value pairs
    while gum confirm "Do you want to add another secret key-value pair?"; do
        echo "Please enter AWS Secret key:"
        SECRET_NAME=$(get_valid_input "Enter AWS Secret key:")
       

        echo "Please enter corresponding secret value:"
        SECRET_VALUE=$(get_valid_input "Enter corresponding secret value" true)
       

        # Add comma if not the first pair
        if [ "$first_pair" = false ]; then
            secret_string+=", "
        fi

        secret_string+="\"$SECRET_NAME\": \"$SECRET_VALUE\""
        first_pair=false
    done

    secret_string+="}"

    echo $secret_string

gum confirm "Review your entries; Do you wish to proceed" || exit 0

    # Use the AWS CLI to create the secret
    aws secretsmanager create-secret \
        --name "$SECRET_STORE_NAME" \
        --region "$REGION" \
        --secret-string "$secret_string"
}

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--margin "1 2" --padding "2 4" \
	'AWS secret manager created/updated!
Secrets successfully stored in Secret Manager'


