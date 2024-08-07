# Variables
DEPLOY_APP_NAME := deploy
DESTROY_APP_NAME := destroy
POSTDEPLOY_APP_NAME := aws-resource

# Commands
GO := go

# Directories
DEPLOY_SRC_DIR := ./setup/cmd/deploy
DESTROY_SRC_DIR := ./setup/cmd/destroy
POSTDEPLOY_SRC_DIR := ./postdeploy
# Targets
.PHONY: all build-deploy build-destroy build-postdeploy setup deploy destroy destroy-cluster destroy-db store-secrets retrieve-creds help

all: deploy

## Build the application
build-deploy:
	cd setup && $(GO) mod tidy
	cd $(DEPLOY_SRC_DIR) && $(GO) build -o ../../../$(DEPLOY_APP_NAME)

build-destroy:
	cd setup && $(GO) mod tidy
	cd $(DESTROY_SRC_DIR) && $(GO) build -o ../../../$(DESTROY_APP_NAME)

build-postdeploy:
	cd postdeploy && $(GO) mod tidy
	cd $(POSTDEPLOY_SRC_DIR) && $(GO) build -o ../$(POSTDEPLOY_APP_NAME)

setup:
	./setup/setup.sh

deploy:
	./deploy

destroy-cluster:
	./destroy -c

destroy-db:
	./destroy -d

destroy:
	./destroy

store-secrets:
	./setup/create_aws_secret.sh

retrieve-creds:
	./setup/create_aws_secret.sh

## Display help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all              bootstraps infrastructure"
	@echo "  build-deploy     builds deploy binary"
	@echo "  build-destroy    builds destroy binary"
	@echo "  build-postdeploy builds postdeploy binary"
	@echo "  deploy           bootstraps infrastructure"
	@echo "  destroy          destroys infrastructure"
	@echo "  destroy-cluster  destroys cluster"
	@echo "  destroy-db       destroys database"
	@echo "  store-secrets    creates aws store and stores secret in store"
	@echo "  setup            installs necessary dependencies"
	@echo "  help             Display this help message"
