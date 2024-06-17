# Targets
.PHONY: all setup deploy destroy store-secrets  help

all: deploy

setup:
	./scripts/setup.sh

deploy:
	./deploy.sh

destroy:
	./destroy.sh


store-secrets:
	./scripts/create_aws_secret.sh



## Display help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all              bootstraps infrastructure"
	@echo "  deploy           bootstraps infrastructure"
	@echo "  destroy          destroys infrastructure"
	@echo "  store-secrets    creates aws store and stores secret in store"
	@echo "  setup            installs necessary dependencies"
	@echo "  help             Display this help message"
