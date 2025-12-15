Partie 3 : Terraform - Infrastructure as Code
Description

Utilisation de Terraform pour exécuter le script Bash de création d’utilisateurs de manière déclarative, reproductible et testable localement.

Terraform va :

Créer un répertoire pour les logs

Vérifier l’existence du script et du fichier users.txt

Rendre le script exécutable

Exécuter le script de création d’utilisateurs

Générer un rapport d’exécution

Installation de Terraform
# Ajouter le dépôt HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Installer Terraform
sudo apt update
sudo apt install terraform -y

# Vérifier l'installation
terraform --version

Structure des fichiers
partie3/
├── main.tf                  # Configuration principale Terraform
├── variables.tf             # Variables d'entrée
├── outputs.tf               # Outputs
├── create_users.sh          # Script Bash (copié depuis partie1)
├── users.txt                # Liste des utilisateurs
└── README.md                # Cette documentation

Utilisation
1. Copier les fichiers nécessaires
cd ~/tp-inf361/partie3

# Copier le script et le fichier users.txt depuis la partie 1
cp ../partie1/create_users.sh .
cp ../partie1/users.txt .

# Vérifier
ls -l

2. Initialiser Terraform
terraform init


Télécharge les providers null et local, initialise le répertoire de travail.

3. Valider la configuration
terraform validate

4. Voir le plan d’exécution (dry-run)
terraform plan

5. Appliquer la configuration
terraform apply


Ou sans confirmation interactive :

terraform apply -auto-approve

6. Consulter les outputs
terraform output

7. Voir l’état actuel
terraform show

8. Détruire l’infrastructure (nettoyage)
terraform destroy


ATTENTION : cela ne supprime pas les utilisateurs créés, uniquement l’état Terraform.

Variables disponibles
Personnaliser les variables

Créer un fichier terraform.tfvars :

group_name     = "students-inf-361"
users_file     = "./users.txt"
script_path    = "./create_users.sh"
log_directory  = "/var/log/terraform-user-creation"


Ou passer directement en ligne de commande :

terraform apply -var="group_name=my-custom-group"

Fonctionnalités Terraform

Infrastructure as Code (IaC)

Déclaratif et versionné

Reproductible localement ou sur plusieurs serveurs

Gestion d’état

Terraform garde trace de ce qui a été créé

Fichier terraform.tfstate généré automatiquement

Idempotence

Peut être exécuté plusieurs fois sans effets indésirables

Applique uniquement les changements nécessaires

Triggers automatiques

Ré-exécution si les fichiers create_users.sh ou users.txt changent

Logging amélioré

Logs centralisés dans /var/log/terraform-user-creation

Rapport d’exécution généré automatiquement

Ressources créées

null_resource.create_log_directory – Crée le répertoire pour les logs

null_resource.verify_files – Vérifie l’existence des fichiers requis

null_resource.make_script_executable – Rend le script Bash exécutable

null_resource.execute_user_creation_script – Exécute le script et copie les logs

local_file.execution_report – Génère un rapport détaillé

Tests et vérifications
Vérifier l’état Terraform
terraform state list
terraform state show null_resource.execute_user_creation_script

Consulter les logs
# Logs Terraform
sudo ls -lah /var/log/terraform-user-creation/

# Rapport d’exécution
sudo cat /var/log/terraform-user-creation/terraform_execution_report.txt

# Logs du script
sudo cat /var/log/terraform-user-creation/user_creation_*.log

Vérifier les utilisateurs créés
getent group students-inf-361
id alice

Personnalisation avancée
Variables d’environnement
export TF_VAR_group_name="my-group"
export TF_VAR_users_file="./users.txt"
terraform apply

Workspaces Terraform (environnements)
terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
terraform workspace list

Mise à jour

Modifier users.txt → terraform apply pour réexécution automatique

Modifier create_users.sh → terraform apply déclenche le trigger grâce au hash MD5

Commandes utiles
terraform fmt
terraform validate
terraform show
terraform state list
terraform import <resource_type>.<name> <id>
terraform refresh
terraform graph | dot -Tpng > graph.png

Avantages

Déclaratif

Versionné

Reproductible

Collaboratif

Historique des changements