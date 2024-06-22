
################################################################################
# ArgoCD Admin Password credentials 

################################################################################

resource "random_password" "argocd" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Argo requires the password to be bcrypt, we use custom provider of bcrypt,
# as the default bcrypt function generates diff for each terraform plan
resource "bcrypt_hash" "argo" {
  cleartext = random_password.argocd.result
}



################################################################################
# Secret Manager 
################################################################################

data "aws_secretsmanager_secret_version" "creds" {
  secret_id = var.secret_store
}
