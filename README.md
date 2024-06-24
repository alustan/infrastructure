
## Introduction

> - **Modular and Extensible Infrastructure Setup with Seamless Data Exchange Between Terraform and Kubernetes**

> - **Serves as infrastructure repo used in testing `alustan` platform orchestrator**


## Architecture

The project architecture consists of the following main components:

- **Cluster**: current implementaion `AWS` : Users are free to add other cloud services.

- **Database**: Current implementation `AWS RDS`: Users are free to add other DB implementations

- **Gitops Bridge**: Shares cloud matadata with kubernetes resources/manifest using argocd cluster secret.

- **Remote Backend**: Remote backend with `S3` and `Dynamodb` with a single flow deploy script.

- **Project is modular and extensible**


## setup

- Run `make setup` to install and configure all needed dependencies. 

- Run `make store-secrets` to create or store secret in aws secret manager

- Run `make deploy` to bootstrap a control cluster

- Run `make retrieve-creds` to retrieve relevant credentials and urls

- Run `make destroy` to destroy the control cluster

- To see all available options run `make help`

- **Consider documenting possible configurations (variables) for your developers: the required and the optional**

## Relevant URLs

- **argocd UI:** `argocd.<workspace>.<domain>`

- **Grafana UI:** `grafana.<workspace>.<domain>`

- **Prometheus UI:** `prometheus.<workspace>.<domain>`

- **Kubecost UI:** `kubecost.<workspace>.<domain>`

- **Argo rollout Dashboard:** `kubectl argo rollouts dashboard -n <namespace>`; Then visit `localhost:3100`

- **Robusta UI:** [robusta](https://home.robusta.dev/)


**This is one of multiple projects that aims to setup a functional platform for seamless application delivery and deployment with less technical overhead**

**Check Out:**

1. [alustan](https://github.com/alustan/alustan)

2. [manifests](https://github.com/alustan/manifests)

4. [backstage-portal](https://github.com/alustan/backstage-portal)

