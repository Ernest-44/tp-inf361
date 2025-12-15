variable "group_name" {
  description = "Nom du groupe principal des étudiants"
  type        = string
  default     = "students-inf-361"
}

variable "users_file" {
  description = "Chemin vers le fichier contenant les utilisateurs"
  type        = string
  default     = "./users.txt"
}

variable "script_path" {
  description = "Chemin vers le script de création d'utilisateurs"
  type        = string
  default     = "./create_users.sh"
}

variable "log_directory" {
  description = "Répertoire pour stocker les logs"
  type        = string
  default     = "/var/log/terraform-user-creation"
}