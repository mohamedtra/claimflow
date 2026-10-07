# Amorçage du compte AWS : ce qui doit exister avant tout le reste et que la CI ne peut pas créer
# elle-même (l'état Terraform partagé, la confiance envers GitHub, les rôles de la CI, le budget).
# Lancé une seule fois depuis le poste de l'administrateur (docs/runbooks/aws-demarrage.md).
#
# L'état de cette pile reste local (terraform.tfstate, ignoré par git) : elle crée le bucket qui
# accueillera l'état des environnements, elle ne peut donc pas y ranger le sien au premier passage.
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Projet  = "claimflow"
      Pile    = "bootstrap"
      GerePar = "terraform"
      Depot   = var.depot_github
    }
  }
}
