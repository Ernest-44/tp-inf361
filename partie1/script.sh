#!/bin/bash

# Script: create_users.sh
# Description: Automatisation de la création d'utilisateurs Linux
# Usage: sudo ./create_users.sh <nom_du_groupe> <fichier_users>

set -euo pipefail  # Arrêt en cas d'erreur

# Vérification des privilèges root
if [[ $EUID -ne 0 ]]; then
   echo " Ce script doit être exécuté en tant que root (sudo)" 
   exit 1
fi

# Vérification des arguments
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <nom_groupe> <fichier_users>"
    echo "Exemple: $0 students-inf-361 users.txt"
    exit 1
fi

GROUP_NAME="$1"
USERS_FILE="$2"
LOG_FILE="user_creation_$(date +%Y%m%d_%H%M%S).log"

# Fonction de logging
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "=========================================="
log_message "Début de l'exécution du script"
log_message "Groupe: $GROUP_NAME"
log_message "Fichier utilisateurs: $USERS_FILE"
log_message "=========================================="

# Vérifier l'existence du fichier users
if [[ ! -f "$USERS_FILE" ]]; then
    log_message " Erreur: Le fichier $USERS_FILE n'existe pas"
    exit 1
fi

# 1. Créer le groupe principal
if getent group "$GROUP_NAME" > /dev/null 2>&1; then
    log_message "  Le groupe $GROUP_NAME existe déjà"
else
    groupadd "$GROUP_NAME"
    log_message " Groupe $GROUP_NAME créé avec succès"
fi

# Configuration des quotas (à activer sur le système de fichiers)
log_message " Vérification des quotas disque..."
if ! command -v quotaon &> /dev/null; then
    log_message " Les outils de quota ne sont pas installés. Installation..."
    apt-get install -y quota quotatool >> "$LOG_FILE" 2>&1 || log_message "⚠️  Impossible d'installer quota"
fi

# Restriction de la commande su pour le groupe
log_message " Configuration de la restriction 'su' pour $GROUP_NAME..."
if ! grep -q "^auth required pam_wheel.so" /etc/pam.d/su; then
    echo "auth required pam_wheel.so deny group=$GROUP_NAME" >> /etc/pam.d/su

    log_message " Restriction 'su' configurée (seul le groupe sudo peut utiliser su)"
fi

#Boucle pour Lire le fichier users.txt ligne par ligne
while IFS=';' read -r username password fullname phone email shell || [[ -n "$username" ]]; do
    # Ignorer les lignes vides et commentaires
    [[ -z "$username" || "$username" =~ ^[[:space:]]*# ]] && continue
    
    log_message "----------------------------------------"
    log_message " Traitement de l'utilisateur: $username"
    
    # 2. Vérifier et installer le shell si nécessaire
    if [[ -n "$shell" ]]; then
        if [[ -f "$shell" ]]; then
            log_message " Shell $shell disponible"
        else
            log_message " Shell $shell non trouvé. Tentative d'installation..."
            shell_package=$(basename "$shell")
            
            if apt-get install -y "$shell_package" >> "$LOG_FILE" 2>&1; then
                log_message " Shell $shell_package installé"
            else
                log_message " Échec installation de $shell. Attribution de /bin/bash"
                shell="/bin/bash"
            fi
        fi
    else
        shell="/bin/bash"
    fi
    
    # 2. Créer l'utilisateur
    if id "$username" &>/dev/null; then
        log_message " L'utilisateur $username existe déjà"
        continue
    fi
    
    useradd -m \
            -c "$fullname,$phone,$email" \
            -s "$shell" \
            -G "$GROUP_NAME,sudo" \
            "$username"
    
    log_message " Utilisateur $username créé"
    log_message "   - Nom complet: $fullname"
    log_message "   - Téléphone: $phone"
    log_message "   - Email: $email"
    log_message "   - Shell: $shell"
    
    # 4. Configurer le mot de passe (haché SHA-512)
    echo "$username:$password" | chpasswd -c SHA512
    log_message " Mot de passe configuré (SHA-512)"
    
    # 5. Forcer le changement de mot de passe à la première connexion
    chage -d 0 "$username"
    log_message " Expiration mot de passe forcée (première connexion)"
    
    # 7. Message de bienvenue personnalisé
    WELCOME_FILE="/home/$username/WELCOME.txt"
    cat > "$WELCOME_FILE" << EOF
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║          Bienvenue $fullname !          ║
║                                                          ║
║   Université de Yaoundé I                              ║
║   INF 3611 : Administration Systèmes et Réseaux        ║
║                                                          ║
║   Username: $username                                  ║
║   Email: $email                                        ║
║   WhatsApp: $phone                                     ║
║                                                          ║
║    IMPORTANT: Changez votre mot de passe maintenant !  ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
    
    chown "$username:$username" "$WELCOME_FILE"
    log_message " Fichier WELCOME.txt créé"
    
    # Ajouter l'affichage dans .bashrc
    BASHRC_FILE="/home/$username/.bashrc"
    if ! grep -q "WELCOME.txt" "$BASHRC_FILE"; then
        echo "" >> "$BASHRC_FILE"
        echo "# Message de bienvenue" >> "$BASHRC_FILE"
        echo "if [ -f ~/WELCOME.txt ]; then" >> "$BASHRC_FILE"
        echo "    cat ~/WELCOME.txt" >> "$BASHRC_FILE"
        echo "fi" >> "$BASHRC_FILE"
        log_message "Message de bienvenue ajouté à .bashrc"
    fi
    
    # 8. Configurer les quotas disque (15 Go)
    if command -v setquota &> /dev/null; then
        # 15 Go = 15728640 blocs de 1K
        setquota -u "$username" 14680064 15728640 0 0 / 2>/dev/null || \
            log_message "  Impossible de définir le quota (activer quotas sur le filesystem)"
        log_message " Quota disque configuré (15 Go)"
    else
        log_message "  setquota non disponible, quota non configuré"
    fi
    
    # 9. Limiter l'utilisation mémoire (20% RAM)
    # Calculer 20% de la RAM totale en Ko
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    RAM_LIMIT_KB=$((TOTAL_RAM_KB * 20 / 100))
    
    # Créer un fichier de limites pour cet utilisateur
    LIMITS_FILE="/etc/security/limits.d/$username.conf"
    cat > "$LIMITS_FILE" << EOF
# Limites pour l'utilisateur $username
$username soft as $RAM_LIMIT_KB
$username hard as $RAM_LIMIT_KB
$username soft nproc 100
$username hard nproc 150
EOF
    
    log_message " Limite mémoire configurée (20% RAM = $((RAM_LIMIT_KB/1024)) Mo)"
    
done < "$USERS_FILE"

log_message "=========================================="
log_message " Script terminé avec succès"
log_message " Log complet disponible dans: $LOG_FILE"
log_message "=========================================="

echo ""
echo " Tous les utilisateurs ont été créés avec succès !"
echo " Consultez le fichier de log: $LOG_FILE"