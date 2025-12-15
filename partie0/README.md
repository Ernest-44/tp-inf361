Partie 0 : Sécurisation et configuration du serveur SSH
1. Procédure pour modifier la configuration SSH

Se connecter avec un utilisateur root ou sudo :

sudo -i


Éditer le fichier de configuration SSH :

sudo nano /etc/ssh/sshd_config


Modifier les paramètres de sécurité selon les recommandations.

Tester la configuration avant le redémarrage :

sudo sshd -t


Redémarrer le service SSH pour appliquer les modifications :

sudo systemctl restart sshd


Vérifier que le service est actif :

sudo systemctl status sshd

2. Risque principal si la procédure n’est pas respectée

Perte d’accès au serveur : une mauvaise configuration peut bloquer toute connexion SSH.

Risques supplémentaires : attaques par brute force, accès non autorisé, élévation de privilèges.


3. Paramètres de sécurité à modifier et justification

Port : 2222 (ou un autre port non standard)
Justification : Réduit les tentatives d’attaques automatiques sur le port SSH par défaut (22).

PermitRootLogin : no
Justification : Interdit la connexion directe en root, oblige à passer par un utilisateur normal, limitant ainsi les risques d’accès complet en cas de compromission.

PasswordAuthentication : no
Justification : Force l’usage de clés SSH, empêchant les attaques par brute force sur les mots de passe.

MaxAuthTries : 3
Justification : Limite le nombre de tentatives de connexion échouées, réduisant le risque de brute force.

AllowUsers / AllowGroups : liste des utilisateurs ou groupes autorisés
Justification : Restreint l’accès SSH uniquement aux comptes spécifiés, empêchant toute connexion non autorisée.

ClientAliveInterval : 300
Justification : Déconnecte automatiquement les sessions inactives, réduisant le risque d’accès non surveillé.

X11Forwarding : no
Justification : Désactive le forwarding graphique si inutile, limitant la surface d’attaque.