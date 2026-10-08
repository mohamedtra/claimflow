variable "region" {
  description = "Région AWS du projet (Paris)."
  type        = string
  default     = "eu-west-3"
}

variable "depot_github" {
  description = "Dépôt GitHub autorisé à prendre les rôles de la CI, au format propriétaire/nom."
  type        = string
  default     = "mohamedtra/claimflow"
}

variable "sujet_oidc_github" {
  description = <<-EOT
    Début du « sub » des jetons OIDC du dépôt : repo:<propriétaire>@<id>/<dépôt>@<id> (format immuable,
    imposé aux dépôts créés après le 15/07/2026). Identifiants : gh api repos/<propriétaire>/<dépôt>
    --jq '.owner.id, .id'.
  EOT
  type        = string
  default     = "repo:mohamedtra@36902772/claimflow@1399766812"

  validation {
    condition     = can(regex("^repo:[^@/]+@[0-9]+/[^@/]+@[0-9]+$", var.sujet_oidc_github))
    error_message = "sujet_oidc_github doit avoir la forme repo:<propriétaire>@<id>/<dépôt>@<id>."
  }
}

variable "email_alertes" {
  description = "Adresse qui reçoit les alertes de budget. À renseigner dans terraform.tfvars (non versionné)."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.email_alertes))
    error_message = "email_alertes doit être une adresse e-mail."
  }
}

variable "budget_mensuel_usd" {
  description = "Plafond mensuel surveillé, en dollars. Les alertes partent à 20 %, 50 % et 100 %."
  type        = number
  default     = 50
}
