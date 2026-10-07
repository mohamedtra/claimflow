# Environnement dev sur AWS (EN-08, ADR-015) : une instance EC2 qui porte l'API, Keycloak et
# PostgreSQL en conteneurs, la SPA sur S3, et CloudFront devant les deux, en HTTPS.
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  # Bucket fourni à l'initialisation : terraform init -backend-config="bucket=<TF_STATE_BUCKET>".
  # Il porte l'identifiant du compte, qui n'a pas sa place dans un dépôt public.
  backend "s3" {
    key          = "envs/dev/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Projet        = "claimflow"
      Environnement = var.environnement
      GerePar       = "terraform"
    }
  }
}

data "aws_caller_identity" "courant" {}

locals {
  compte = data.aws_caller_identity.courant.account_id
  nom    = "claimflow-${var.environnement}"
  ssm    = "/claimflow/${var.environnement}"
}
