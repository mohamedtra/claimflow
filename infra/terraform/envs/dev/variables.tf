variable "region" {
  description = "Région AWS (Paris)."
  type        = string
  default     = "eu-west-3"
}

variable "environnement" {
  description = "Nom de l'environnement, repris dans les noms et les chemins SSM."
  type        = string
  default     = "dev"
}

variable "zone" {
  description = "Zone de disponibilité de l'instance et de son volume de données."
  type        = string
  default     = "eu-west-3a"
}

variable "type_instance" {
  description = "Type d'instance : t3.small (2 vCPU, 2 Gio), éligible à l'offre gratuite (ADR-015)."
  type        = string
  default     = "t3.small"
}

variable "taille_donnees_gio" {
  description = "Taille du volume de données (PostgreSQL), conservé si l'instance est remplacée."
  type        = number
  default     = 10
}

variable "arret_nocturne" {
  description = "Arrêter l'instance la nuit pour économiser les heures de calcul."
  type        = bool
  default     = true
}

variable "heure_arret" {
  description = "Heure d'arrêt de l'instance (Europe/Paris)."
  type        = number
  default     = 23
}

variable "heure_demarrage" {
  description = "Heure de démarrage de l'instance (Europe/Paris)."
  type        = number
  default     = 8
}

variable "duree_sauvegardes_jours" {
  description = "Durée de conservation des sauvegardes PostgreSQL dans S3."
  type        = number
  default     = 14
}
