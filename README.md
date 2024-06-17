
## Introduction

> - **Modular and Extensible Infrastructure Setup with Seamless Data Exchange Between Terraform and Kubernetes**

> - **Serves as infrastructure repo used in testing terraform-controller**


## Architecture

The project architecture consists of the following main components:

- **Cluster**: current implementaion `AWS` : Users are free to add other cloud services.

- **Database**: Current implementation `AWS RDS`: Users are free to add other DB implementations

- **Gitops Bridge**: Share cloud matadata with kubernetes resources/manifest using argocd cluster secret.

- **Project is modular and extensible**


## setup

- Run `make setup` to install and configure all needed dependencies. 

- Run `make store-secrets` to create or store secret in aws secret manager

- Run `make deploy` to bootstrap a control cluster

- Run `make destroy` to destroy the control cluster

- To see all available options run `make help`

## Relevant URLs

- **argocd UI:** `argocd.<workspace>.<domain>`

- **Grafana UI:** `grafana.<workspace>.<domain>`

- **Prometheus UI:** `prometheus.<workspace>.<domain>`

- **Kubecost UI:** `kubecost.<workspace>.<domain>`

- **Argo rollout Dashboard:** `kubectl argo rollouts dashboard -n <namespace>`; Then visit `localhost:3100`

- **Robusta UI:** [robusta](https://home.robusta.dev/)

- **To list all relevant URLs** `terraform output -raw retrieve_creds`; Execute the output


**This is one of multiple projects that aims to setup a functional platform for seemless app deployment with less technical overhead**

**Check Out:**

1. [Terraform-controller](https://github.com/alustan/terraform-controller)

2. [App-controller](https://github.com/alustan/app-controller)

3. [Cluster-manifests](https://github.com/alustan/cluster-manifests)

4. [Alustan-Backstage](https://github.com/alustan/backstage)

