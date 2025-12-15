# Partie 1 : Script Bash - Automatisation de création d'utilisateurs

##  Description

Script Bash pour automatiser la création d'utilisateurs Linux avec toutes les configurations de sécurité requises.

##  Prérequis

```bash
sudo apt update
sudo apt install -y quota quotatool
```

##  Structure des fichiers

```
partie1/
├── create_users.sh          # Script principal
├── users.txt                # Fichier des utilisateurs 
├── README.md                # Cette documentation
└── logs/                    # Logs d'exécution (créés automatiquement)
```

##  Format du fichier users.txt

```
username;default_password;full_name;phone;email;preferred_shell
```

## Utilisation

### 1. Rendre le script exécutable

```bash
chmod +x create_users.sh
```

### 2. Exécuter le script

```bash
sudo ./create_users.sh students-inf-361 users.txt
```

### 3. Vérifier les utilisateurs créés

```bash
# Lister les utilisateurs du groupe
getent group students-inf-361

# Vérifier les détails d'un utilisateur
id alice
finger alice
```

## Fonctionnalités implémentées

-  Création du groupe `students-inf-361`
-  Création automatique des utilisateurs avec toutes leurs infos
-  Vérification et installation du shell préféré
-  Ajout au groupe principal et au groupe sudo
-  Hachage des mots de passe (SHA-512)
-  Expiration forcée du mot de passe (première connexion)
-  Restriction de la commande `su` pour le groupe
-  Message de bienvenue personnalisé (WELCOME.txt)
-  Quota disque de 15 Go par utilisateur
-  Limitation mémoire à 20% de la RAM
-  Logging complet avec date/heure

##  Sécurité

### Restrictions implémentées

1. **Commande su** : Seuls les membres du groupe `sudo` (pas `students-inf-361`) peuvent utiliser `su`
2. **Quotas disque** : Maximum 15 Go par utilisateur
3. **Mémoire** : Processus limités à 20% de la RAM totale
4. **Mots de passe** : Hachés avec SHA-512, changement obligatoire à la première connexion

### Configuration SSH recommandée

```bash
# Éditer la configuration SSH
sudo nano /etc/ssh/sshd_config

# Paramètres recommandés :
Port 2222
PermitRootLogin no
PasswordAuthentication no
MaxAuthTries 3
AllowGroups students-inf-361

# Tester et redémarrer
sudo sshd -t
sudo systemctl restart sshd
```

##  Activation des quotas (si nécessaire)

```bash
# Éditer /etc/fstab et ajouter usrquota,grpquota
sudo nano /etc/fstab
# Exemple: UUID=xxx / ext4 defaults,usrquota,grpquota 0 1

# Remonter et initialiser les quotas
sudo mount -o remount /
sudo quotacheck -cum /
sudo quotaon -v /
```

##  Tests

### Tester la connexion d'un utilisateur

```bash
# Se connecter en tant qu'alice
su - alice

# Le message WELCOME.txt devrait s'afficher
# Le système demandera de changer le mot de passe
```

### Vérifier les quotas

```bash
sudo quota -u alice
```

### Vérifier les limites mémoire

```bash
cat /etc/security/limits.d/alice.conf
```

##  Logs

Chaque exécution génère un fichier log avec timestamp :
```
user_creation_20251214_143052.log
```

##  Troubleshooting

### Problème : Quotas non appliqués
**Solution** : Activer les quotas sur le filesystem (voir section Activation des quotas)

### Problème : Shell non disponible
**Solution** : Le script installe automatiquement le shell ou revient à `/bin/bash`

### Problème : Restriction su ne fonctionne pas
**Solution** : Vérifier `/etc/pam.d/su` contient `auth required pam_wheel.so group=sudo`
