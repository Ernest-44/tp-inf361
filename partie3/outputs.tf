# Fichier séparé pour les outputs (optionnel, déjà inclus dans main.tf)

output "terraform_version" {
  description = "Version de Terraform utilisée"
  value       = "Terraform ${terraform.version}"
}

output "timestamp" {
  description = "Horodatage de l'exécution"
  value       = timestamp()
}