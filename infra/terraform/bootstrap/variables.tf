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
