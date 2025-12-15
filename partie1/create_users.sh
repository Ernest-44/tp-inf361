#!/bin/bash

# TP INF 3611 – Automatisation de la création d’utilisateurs
# Partie 1 : Script Bash

# Fichier de log pour garder les traces d’exécution
LOGFILE="/var/log/create_users.log"
exec >> "$LOGFILE" 2>&1
echo "===== Début du script : $(date) ====="


if [ "$EUID" -ne 0 ]; then
  echo "Erreur : le script doit être exécuté avec les permission root"
  exit 1
fi

# Nom du groupe passé en paramètre
GROUP_NAME="$1"

if [ -z "$GROUP_NAME" ]; then
  echo "Usage : sudo ./create_users.sh students-inf-361"
  exit 1
fi

# Création du groupe s’il n’existe pas
groupadd -f "$GROUP_NAME"
echo "Groupe $GROUP_NAME prêt"

# Installation des outils nécessaires (quota, cgroups)
apt update -y
apt install -y quota cgroup-tools

# Activation des quotas disque (15 Go max par utilisateur)
mount | grep usrquota || sed -i 's/errors=remount-ro/errors=remount-ro,usrquota/g' /etc/fstab
mount -o remount /

quotacheck -cum /
quotaon /

# Calcul de 20 % de la RAM totale
TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_LIMIT=$((TOTAL_RAM * 20 / 100))
echo "Limite mémoire par utilisateur : ${MEM_LIMIT} KB"


while IFS=";" read -r username password fullname phone email shell
do
  echo "---- Création de l'utilisateur $username ----"

  # Vérification de l’existence du shell
  if [ ! -x "$shell" ]; then
    echo "Shell $shell absent, tentative d'installation si echec alors votre shell sera /bin/bash"
    apt install -y "$(basename $shell)" || shell="/bin/bash"
  fi

  # Hachage du mot de passe (SHA-512)
  HASHED_PASS=$(openssl passwd -6 "$password")

  # Création de l’utilisateur avec home, shell et infos
  useradd -m -s "$shell" \
    -c "$fullname | WhatsApp:$phone | Email:$email" \
    -p "$HASHED_PASS" "$username"

  # Ajout au groupe students-inf-361
  usermod -aG "$GROUP_NAME" "$username"

  # Ajout au groupe sudo
  usermod -aG sudo "$username"

  # Forcer le changement de mot de passe à la première connexion
  chage -d 0 "$username"

  # Message de bienvenue personnalisé
  echo "Bienvenue $fullname sur le serveur INF3611" > /home/$username/WELCOME.txt
  echo "cat ~/WELCOME.txt" >> /home/$username/.bashrc
  chown "$username:$username" /home/$username/WELCOME.txt

  # Limite d’espace disque : 15 Go
  setquota -u "$username" $((15*1024*1024)) $((15*1024*1024)) 0 0 /

  # Limite mémoire via cgroups (20 % RAM)
  cgcreate -g memory:/$username
  echo "${MEM_LIMIT}K" > /sys/fs/cgroup/memory/$username/memory.limit_in_bytes

  echo "Utilisateur $username créé avec succès"

done < users.txt

# Interdire la commande su aux membres du groupe
echo "auth required pam_wheel.so deny group=$GROUP_NAME" >> /etc/pam.d/su

echo "===== Fin du script : $(date) ====="

