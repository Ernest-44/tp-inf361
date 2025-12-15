Partie 2 : Playbook Ansible - Automatisation avec emails
Description

Playbook Ansible qui automatise la création d’utilisateurs Linux et configure leur environnement.
Pour chaque utilisateur, un fichier de bienvenue WELCOME.txt est créé et peut être affiché automatiquement.
Le playbook prévoit également l’envoi d’un email personnalisé avec les informations de connexion (optionnel pour tests locaux).

Testé en local sur Ubuntu Desktop pour le TP.

Installation
# Installer Ansible et dépendances
sudo apt update
sudo apt install -y ansible sshpass python3-pip mailutils quota quotatool zsh

# Vérifier l'installation
ansible --version

Structure des fichiers
partie2/
├── create_users.yml         # Playbook principal
├── users.yml                # Liste des utilisateurs (format YAML)
├── inventory.ini            # Inventaire des serveurs (localhost pour test)
├── gmail_setup.md           # Guide configuration email (optionnel)
└── README.md                # Cette documentation

Format du fichier users.yml
---
users:
  - username: alice
    password: Pass123!
    fullname: Alice Dupont
    phone: +237690123456
    email: alice@example.com
    shell: /bin/bash
  
  - username: bob
    password: SecureP@ss
    fullname: Bob Martin
    phone: +237691234567
    email: bob@example.com
    shell: /bin/zsh


Pour le TP, quelques utilisateurs suffisent pour tester.
Si tu disposes d’un users.txt, tu peux le convertir rapidement en YAML.

Utilisation
1. Configurer les emails (optionnel en test local)

Modifier dans create_users.yml :

vars:
  smtp_host: smtp.gmail.com
  smtp_port: 587
  smtp_user: "votre-email@gmail.com"
  smtp_password: "votre-app-password"


Pour un test local sans envoi d’emails, tu peux commenter la task mail dans le playbook.

2. Tester la syntaxe du playbook
ansible-playbook create_users.yml -i inventory.ini --syntax-check

3. Exécution en simulation (dry-run)
ansible-playbook create_users.yml -i inventory.ini --check

4. Exécuter le playbook
ansible-playbook create_users.yml -i inventory.ini

5. Exécuter avec verbosité (debug)
ansible-playbook create_users.yml -i inventory.ini -vvv

Fonctionnalités

Création automatique des utilisateurs avec toutes leurs informations

Ajout au groupe principal et au groupe sudo

Configuration du shell préféré

Hachage des mots de passe (SHA-512)

Expiration forcée du mot de passe (première connexion)

Fichier WELCOME.txt personnalisé et affichage automatique via .bashrc

Quota disque de 15 Go par utilisateur

Limite mémoire à 20% de la RAM

Optionnel : envoi d’un email personnalisé avec identifiants et commandes utiles

Avantages d’Ansible

Idempotence : Peut être exécuté plusieurs fois sans effets indésirables

Gestion multi-serveurs : Même si ici testé en local, le playbook peut s’adapter à plusieurs serveurs

Logging structuré : Logs détaillés et organisés

Modularité : Facile de réutiliser les tasks

Vérifications
Vérifier les utilisateurs créés
ansible localhost -i inventory.ini -m shell -a "getent group students-inf-361"

Vérifier les quotas
ansible localhost -i inventory.ini -m shell -a "quota -u alice"

Consulter les logs
ansible localhost -i inventory.ini -m shell -a "tail -50 /var/log/user_creation_ansible_*.log"

Tests
# Exécuter le playbook
sudo ansible-playbook create_users.yml -i inventory.ini

# Se connecter à un utilisateur
su - alice

# Vérifier le message WELCOME.txt
# Vérifier l'email si SMTP configuré

Troubleshooting
Emails non envoyés

Vérifier les credentials SMTP dans create_users.yml

Tester manuellement : echo "test" | mail -s "test" votre-email@example.com

Consulter les logs : /var/log/mail.log

Pour tester sans email, commenter la task mail dans le playbook

"Permission denied"
# Vérifier les privilèges sudo
sudo ansible-playbook create_users.yml -i inventory.ini --ask-become-pass

Module 'mail' non trouvé
pip3 install ansible
# OU commenter la task d'envoi d'email
