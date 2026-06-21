# Plan de Restauration — Service Sauvegarde VM QNAP

## Vue d'ensemble

Ce document décrit la procédure complète de restauration d'une VM Mint-Infra-Server depuis ses sauvegardes. Le processus couvre la vérification des fichiers, la restauration du disque, la redéfinition de la VM, et la validation opérationnelle.

**Durée estimée:** 15-45 min (selon la taille du disque et les problèmes rencontrés)

**Risque:** Disruptif pour la VM cible — arrêter tous services critiques avant restauration.

---

## 1. Prérequis

### 1.1 Accès et authentification

- [ ] Accès SSH QNAP en tant qu'admin@192.168.8.220
- [ ] Clé SSH locale: `~/.ssh/id_ed25519` (permissions 600)
- [ ] Accès root ou sudo sur QNAP (pour opérations virsh/disque)

### 1.2 État des VM

- [ ] VM cible arrêtée (ou disposée à être arrêtée)
  ```bash
  /share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh list --all | grep Mint
  # Doit afficher: running ou shut off
  ```

- [ ] Pas de snapshot actif sur la VM cible
  ```bash
  /share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh snapshot-list 61a8416a-feb3-4f82-9bb0-a1b4d326f767
  # Doit être vide ou acceptable
  ```

### 1.3 Espace disque QNAP

- [ ] Au moins 50G libres sur /share (pour opérations temporaires)
  ```bash
  df -h /share | tail -n 1
  # Doit afficher >50G dans colonne "Avail"
  ```

### 1.4 Fichiers de sauvegarde accessibles

- [ ] Répertoire de backup accessible
  ```bash
  ls -lh /share/InfraData/03_Backups/02_Linux/01_Backups_VM/ | head -n 5
  # Doit afficher au moins 1 paire (disque + XML)
  ```

### 1.5 Chemins QNAP vérifiés

- [ ] virsh accessible
  ```bash
  /share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh --version
  ```

- [ ] qemu-img accessible
  ```bash
  /share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/qemu-img --version
  ```

---

## 2. Sélection du Fichier de Sauvegarde

### 2.1 Lister les sauvegardes disponibles

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'ls -lh /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_*.qcow2'
```

**Résultat attendu:**
```
-rw-r--r-- 1 root root 12G 2026-06-20 18:21 mint-infra-server_2026-06-20_18-21-00.qcow2
-rw-r--r-- 1 root root 12G 2026-06-20 18:28 mint-infra-server_2026-06-20_18-28-05.qcow2
```

### 2.2 Choisir le backup à restaurer

**Critères:**

- **Point de restauration récent:** Généralement, le plus récent est préférable
- **Point de restauration connu/testé:** Si un backup spécifique a été validé
- **Avant/après un événement:** Si corruption/changement détecté à une date

**Recommandation:** Utiliser le **plus récent** sauf si corrupted ou knowns issues.

**Sélection:**
```bash
# Récupérer le dernier backup
BACKUP_TS=$(ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'ls -1tr /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_*.qcow2 | tail -n 1 | xargs basename | sed "s/mint-infra-server_//;s/.qcow2//"')

echo "Backup sélectionné: $BACKUP_TS"
# Sortie: Backup sélectionné: 2026-06-20_18-28-05
```

### 2.3 Variables d'environnement pour la restauration

**Créer un fichier de configuration locale:**
```bash
# Fichier: ~/.ssh/qnap_restore_config.sh
export QNAP_HOST="192.168.8.220"
export QNAP_USER="admin"
export SSH_KEY="$HOME/.ssh/id_ed25519"
export BACKUP_TS="2026-06-20_18-28-05"
export BACKUP_DIR="/share/InfraData/03_Backups/02_Linux/01_Backups_VM"
export BACKUP_DISK="$BACKUP_DIR/mint-infra-server_${BACKUP_TS}.qcow2"
export BACKUP_XML="$BACKUP_DIR/mint-infra-server_${BACKUP_TS}.xml"
export VIRSH="/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh"
export QEMU_IMG="/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/qemu-img"
export VM_NAME="Mint-Infra-Server"
export VM_UUID="61a8416a-feb3-4f82-9bb0-a1b4d326f767"
export TARGET_DISK_PATH="/share/InfraData/VMs/Mint-Infra-Server/disk.qcow2"
```

**Charger les variables:**
```bash
source ~/.ssh/qnap_restore_config.sh
```

---

## 3. Vérification des Fichiers de Sauvegarde

### 3.1 Vérifier la présence et la taille des fichiers

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "ls -lh '$BACKUP_DISK' '$BACKUP_XML' 2>/dev/null || echo 'FICHIERS MANQUANTS'"
```

**Résultat attendu:**
```
-rw-r--r-- 1 root root 12G 2026-06-20 18:28 /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.qcow2
-rw-r--r-- 1 root root 4.2K 2026-06-20 18:28 /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.xml
```

**Alerte si:**

- Fichier disque absent ou vide (< 100M)
- Fichier XML absent ou vide
- Taille disque diminuée d'une session à l'autre (possible corruption)

### 3.2 Vérifier l'intégrité du disque qcow2

**Commande (peut prendre 5-10 min pour 12G):**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$QEMU_IMG' check -r all '$BACKUP_DISK'"
```

**Résultat attendu:**
```
No errors were found on the image.
```

**Erreur caractéristique:**
```
ERROR: something is wrong here
File corruption detected
```

**Action en cas d'erreur:**
- Ne pas utiliser ce backup
- Choisir un backup plus ancien
- Voir section **8. Erreurs Fréquentes — Corruption**

### 3.3 Vérifier l'intégrité du fichier XML

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "cat '$BACKUP_XML' | head -n 5"
```

**Résultat attendu:**
```
<?xml version='1.0' encoding='UTF-8'?>
<domain type='kvm'>
  <name>Mint-Infra-Server</name>
  <uuid>61a8416a-feb3-4f82-9bb0-a1b4d326f767</uuid>
  ...
```

**Alerte si:**
- Pas de `<?xml version`
- Fichier vide ou corrupted
- XML invalide (voir section **3.4**)

### 3.4 Valider le XML (optionnel mais recommandé)

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' domxml-validate '$BACKUP_XML' && echo 'XML_VALID' || echo 'XML_INVALID'"
```

**Résultat attendu:**
```
XML_VALID
```

**En cas d'invalidité:**
- XML corruption possible
- Utiliser un backup plus ancien
- Recréer la définition manuelle (avancé)

---

## 4. Arrêt de la VM (si en cours d'exécution)

### 4.1 Vérifier l'état actuel

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' domstate '$VM_UUID'"
```

**Résultat attendu:**
```
shut off
```

Ou
```
running
```

### 4.2 Arrêter la VM proprement

**Si état = running:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' shutdown '$VM_UUID'" && sleep 30
```

**Vérifier l'arrêt:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' domstate '$VM_UUID'"
```

**Résultat attendu:**
```
shut off
```

### 4.3 Forcer l'arrêt si nécessaire

**Si shutdown bloquée (rare):**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' destroy '$VM_UUID'" && sleep 10
```

---

## 5. Restauration du Disque

### 5.1 Déterminer le chemin cible du disque

**Question:** Où était le disque original avant sauvegarde ?

**Répondre en consultant les métadonnées:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "cat '$BACKUP_XML' | grep -A 2 '<source file'"
```

**Résultat attendu:**
```
<source file='/share/InfraData/VMs/Mint-Infra-Server/disk.qcow2'/>
```

**Stocker le chemin:**
```bash
TARGET_DISK_PATH="/share/InfraData/VMs/Mint-Infra-Server/disk.qcow2"
```

### 5.2 Sauvegarder le disque courant (optionnel mais prudent)

**Si un disque existe déjà à cette location:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'cp '"$TARGET_DISK_PATH"' '"$TARGET_DISK_PATH"'.backup.before-restore.$(date +%s)'
```

### 5.3 Restaurer le disque via copie sparse

**Stratégie A: Copie directe (rapide, préservant le format qcow2)**

**Prérequis:** Espace libre >= taille du disque source

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'set -e; \
   echo "Copie du disque..."; \
   cp --sparse=always '"$BACKUP_DISK"' '"$TARGET_DISK_PATH"'; \
   echo "Restauration disque terminée"; \
   ls -lh '"$TARGET_DISK_PATH"'
  '
```

**Durée:** ~5-10 min pour 12G (selon I/O NAS)

**Résultat attendu:**
```
Copie du disque...
Restauration disque terminée
-rw-r--r-- 1 root root 12G 2026-06-20 18:40 /share/InfraData/VMs/Mint-Infra-Server/disk.qcow2
```

### 5.4 Vérifier le disque restauré

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$QEMU_IMG' check -r all '$TARGET_DISK_PATH'"
```

**Résultat attendu:**
```
No errors were found on the image.
```

**Alerte si erreurs:** Restauration échouée, rollback via `.backup` créé en 5.2

---

## 6. Restauration de la Définition VM

### 6.1 Vérifier si la VM est déjà définie

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' dominfo '$VM_UUID' >/dev/null 2>&1 && echo 'DEFINIE' || echo 'NON_DEFINIE'"
```

### 6.2 Cas A: VM déjà définie (chemin disque identique)

**Action:** Aucune, passer à section **7. Démarrage de la VM**

**Raison:** Le disque original était au même chemin, la définition reste valide.

### 6.3 Cas B: VM non définie ou chemin disque change

**Tâche 1: Récupérer le XML de sauvegarde**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "cat '$BACKUP_XML'" > /tmp/vm_restore_definition.xml
```

**Tâche 2: Éditer le XML localement si chemin disque a changé (optionnel)**

Exemples:
- Source: `/share/InfraData/VMs/Mint-Infra-Server/disk.qcow2`
- Cible: `/share/InfraData/VMs/Mint-Infra-Server/disk.qcow2`
→ Pas de changement

Ou:
- Source: `/vms/mint/disk.qcow2`
- Cible: `/share/InfraData/VMs/Mint-Infra-Server/disk.qcow2`
→ Éditer le XML

**Édition (si nécessaire):**
```bash
# Localement
sed -i "s|<source file='.*'/>|<source file='$TARGET_DISK_PATH'/>|" /tmp/vm_restore_definition.xml

# Vérifier
grep "source file" /tmp/vm_restore_definition.xml
```

**Tâche 3: Copier le XML sur le QNAP**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'cat > /tmp/vm_restore_definition.xml' < /tmp/vm_restore_definition.xml
```

**Tâche 4: Redéfinir la VM**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' define /tmp/vm_restore_definition.xml && echo 'VM_DEFINIE'"
```

**Résultat attendu:**
```
Domain Mint-Infra-Server defined from /tmp/vm_restore_definition.xml
VM_DEFINIE
```

**Vérifier la définition:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' dominfo '$VM_UUID'"
```

---

## 7. Démarrage de la VM

### 7.1 Vérifier le prérequis (disque + définition)

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'set -e; \
   [ -f '"$TARGET_DISK_PATH"' ] && echo "Disque: OK" || echo "Disque: MANQUANT"; \
   '"$VIRSH"' dominfo '"$VM_UUID"' >/dev/null && echo "Définition: OK" || echo "Définition: MANQUANTE"
  '
```

**Résultat attendu:**
```
Disque: OK
Définition: OK
```

### 7.2 Démarrer la VM

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' start '$VM_UUID'" && sleep 10
```

**Résultat attendu:**
```
Domain Mint-Infra-Server started
```

### 7.3 Vérifier l'état démarrage

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' domstate '$VM_UUID'"
```

**Résultat attendu:**
```
running
```

**Alerte si:**
- État = `shut off` : VM s'est arrêtée peu après démarrage (erreur interne)
- État = `paused` : VM suspendue
- État = `crashed` : Crash au démarrage

---

## 8. Validation Post-Restauration

### 8.1 Attendre l'initialisation système (2-5 min)

Laisser la VM démarrer complètement avant tests.

### 8.2 Vérifier la connectivité réseau

**Via QNAP (console virsh):**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' console '$VM_UUID' <<< 'ip addr | grep inet' 2>/dev/null" || echo "(console peut être indisponible)"
```

**Ou via SSH local (si VM sur même réseau):**
```bash
ssh -i ~/.ssh/id_ed25519 sebastien@192.168.8.189 \
  'hostname; ip addr show; uname -a'
```

**Résultat attendu:**
```
mint-infra-server
inet 192.168.8.189/24 brd 192.168.8.255 scope global dynamic eth0
Linux mint-infra-server 5.15.0-... #1 SMP ... x86_64 GNU/Linux
```

### 8.3 Vérifier les services critiques (si Docker)

**Commande SSH dans la VM:**
```bash
ssh -i ~/.ssh/id_ed25519 sebastien@192.168.8.189 \
  'docker ps -a && docker volume ls'
```

**Résultat attendu:**
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
(les containers de production)
```

### 8.4 Vérifier le filesystem / partitions

**Commande SSH dans la VM:**
```bash
ssh -i ~/.ssh/id_ed25519 sebastien@192.168.8.189 \
  'df -h && lsblk'
```

**Résultat attendu:**
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda1        40G   20G   17G  55% /
(et autres partitions)
```

### 8.5 Vérifier les logs de démarrage (optionnel)

**Commande SSH dans la VM:**
```bash
ssh -i ~/.ssh/id_ed25519 sebastien@192.168.8.189 \
  'dmesg | tail -n 50; tail -n 50 /var/log/syslog'
```

**Alerte si:**
- Erreurs filesystem
- Erreurs driver
- Panics kernel

### 8.6 Test applicatif (selon contexte)

**Exemple Docker Compose:**
```bash
ssh -i ~/.ssh/id_ed25519 sebastien@192.168.8.189 \
  'cd /opt/portainer && docker compose ps'
```

**Résultat attendu:**
```
NAME                COMMAND             STATUS    PORTS
portainer           /portainer          Up 2 min  0.0.0.0:8000->8000/tcp, ...
```

---

## 9. Cas Particuliers

### 9.1 Restauration avec changement de chemin disque

**Scénario:** Disque original était en `/vms/mint/disk.qcow2`, nouveau chemin `/share/InfraData/VMs/Mint-Infra-Server/disk.qcow2`

**Procédure:**
1. Copier le disque au nouveau chemin (section **5.3**)
2. Éditer le XML pour mettre à jour `<source file>` (section **6.3**)
3. Redéfinir la VM (section **6.4**)
4. Démarrer (section **7**)

**Script automation:**
```bash
#!/bin/bash
set -e

BACKUP_DISK="/share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.qcow2"
BACKUP_XML="/share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.xml"
TARGET_DISK="/share/InfraData/VMs/Mint-Infra-Server/disk.qcow2"
TARGET_XML="/tmp/vm_restored.xml"

VIRSH="/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh"
VM_UUID="61a8416a-feb3-4f82-9bb0-a1b4d326f767"

echo "1. Copie disque..."
cp --sparse=always "$BACKUP_DISK" "$TARGET_DISK"

echo "2. Édition XML..."
cat "$BACKUP_XML" | sed "s|<source file='.*'/>|<source file='$TARGET_DISK'/>|" > "$TARGET_XML"

echo "3. Redéfinition VM..."
"$VIRSH" define "$TARGET_XML"

echo "4. Démarrage..."
"$VIRSH" start "$VM_UUID"

echo "OK"
```

### 9.2 Restauration depuis backup vdi (rare)

**Scénario:** Disque sauvegardé en format VDI au lieu de qcow2

**Procédure conversion:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$QEMU_IMG' convert -f vdi -O qcow2 '$BACKUP_DISK_VDI' '$TARGET_DISK_QCOW2'"
```

### 9.3 Restauration avec snapshot actif

**Scénario:** Le backup contenait des snapshots internes

**État:** Les snapshots sont inclus dans le fichier qcow2 → Pas d'action spéciale

**Optionnel:** Fusionner les snapshots après restauration (avancé)
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$QEMU_IMG' commit '$TARGET_DISK' && echo 'Snapshots fusionnés'"
```

### 9.4 Restauration en parallèle (2e VM)

**Scénario:** Cloner la sauvegarde pour créer une 2e VM de test

**Procédure:**
1. Copier le disque à nouveau chemin: `/share/InfraData/VMs/Mint-Test/disk.qcow2`
2. Copier et éditer le XML:
   ```bash
   sed 's/<uuid>.*<\/uuid>/<uuid>NEW_UUID</uuid>/' \
       's/<name>.*<\/name>/<name>Mint-Test</name>/' \
       "$BACKUP_XML" > /tmp/vm_test.xml
   ```
3. Générer un nouveau UUID:
   ```bash
   NEW_UUID=$(uuidgen)
   sed -i "s/<uuid>.*<\/uuid>/<uuid>$NEW_UUID<\/uuid>/" /tmp/vm_test.xml
   ```
4. Redéfinir et démarrer

---

## 10. Erreurs Fréquentes et Solutions

### 10.1 Erreur: "VM not found" ou "No active domain"

**Message exact:**
```
error: VM not found
```

**Cause:** UUID ou définition invalide/manquant

**Solution:**
1. Vérifier l'UUID:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     "'$VIRSH' list --all | grep -i mint"
   ```

2. Utiliser le nom au lieu de UUID:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     "'$VIRSH' domstate Mint-Infra-Server"
   ```

3. Si toujours absent, redéfinir depuis XML (section **6.3**)

### 10.2 Erreur: "Cannot access backing file" ou "No such file"

**Message exact:**
```
error: Cannot access backing file
error: No such file or directory
```

**Cause:** Chemin disque incorrect dans la définition ou disque introuvable

**Vérification:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "[ -f '$TARGET_DISK_PATH' ] && echo 'FILE_OK' || echo 'FILE_MISSING'"
```

**Solution:**
1. Vérifier chemin dans XML
2. Relancer restauration disque (section **5**)
3. Redéfinir VM (section **6**)

### 10.3 Erreur: "qemu-img check: failed" ou "Corruption detected"

**Message exact:**
```
ERROR: ...
File corruption detected
```

**Cause:** Disque corrompu (transfert cassé, filesystem endommagé)

**Solution:**
1. Ne pas utiliser ce backup
2. Tenter backup plus ancien:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'ls -1tr /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_*.qcow2 | head -n -1'
   ```
3. Relancer procédure depuis section **2. Sélection**

### 10.4 Erreur: "No space left on device"

**Message exact:**
```
error: No space left on device
```

**Cause:** Espace disque insuffisant pour copie

**Vérification:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'df -h /share | tail -n 1'
```

**Solution:**
1. Libérer au moins 50G:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'rm -f /tmp/*.tmp /var/log/vm_backup_qnap.log.* 2>/dev/null; df -h /share'
   ```

2. Archiver ou supprimer backups anciens (voir maintenance.md)

3. Ajouter espace disque physique (long terme)

### 10.5 Erreur: "XML validation failed"

**Message exact:**
```
error: XML validation failed
```

**Cause:** XML malformé ou syntaxe invalide

**Diagnostic:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "cat '$BACKUP_XML' | grep -E '^<|^$' | head -n 20"
```

**Solution:**
1. Corriger manuellement le XML
2. Utiliser un backup plus ancien avec XML valide
3. Recréer définition manuellement (avancé)

### 10.6 Erreur: "Domain is still running" lors de redéfinition

**Message exact:**
```
error: Domain is still running
```

**Cause:** VM non arrêtée avant restauration

**Solution:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' shutdown '$VM_UUID'" && sleep 30

# Forcer si nécessaire:
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' destroy '$VM_UUID'" && sleep 10
```

### 10.7 Erreur: "Timeout" pendant copie disque

**Message exact:**
```
timeout or hanging
```

**Cause:** I/O saturée, réseau lent, ou disque fragmenté

**Solution:**
1. Vérifier charge QNAP:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 'top -bn1 | head -n 5'
   ```

2. Attendre charge basse et relancer

3. Utiliser conversio qemu-img à la place de cp (plus lent mais plus stable):
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     "'$QEMU_IMG' convert -p '$BACKUP_DISK' '$TARGET_DISK'"
   ```

### 10.8 Erreur: "SSH connection refused" ou "Cannot reach QNAP"

**Message exact:**
```
Connection refused
Network unreachable
```

**Cause:** QNAP offline, firewall, ou clé SSH invalide

**Diagnostic:**
```bash
ping 192.168.8.220
ssh -i ~/.ssh/id_ed25519 -vvv admin@192.168.8.220 'echo OK'
ls -l ~/.ssh/id_ed25519
```

**Solution:**
1. Vérifier QNAP accessible: `ping 192.168.8.220`
2. Vérifier clé SSH (permissions 600): `chmod 600 ~/.ssh/id_ed25519`
3. Tester connexion: `ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 'echo OK'`

### 10.9 Erreur: "VM started but cannot connect"

**Message exact:**
```
virsh domstate = running
but SSH/console unreachable
```

**Cause:** VM démarrée mais pas initialisée, ou problème réseau interne

**Diagnostic:**
```bash
# Via console virsh
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  "'$VIRSH' console '$VM_UUID'" &

# Attendre 3-5 min pour initialisation complète
sleep 300

# Retenter
ssh -i ~/.ssh/id_ed25519 sebastien@192.168.8.189 'hostname'
```

**Solution:**
1. Attendre 5-10 min (initialisation)
2. Vérifier réseau: `ip addr` dans console
3. Rebooter VM si nécessaire:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     "'$VIRSH' reboot '$VM_UUID'"
   ```

---

## 11. Checklist de Restauration Rapide

Imprimer ou copier cette checklist:

```
[ ] 1. Prérequis vérifiés (accès, espace, chemins)
[ ] 2. Backup sélectionné: ___________________
[ ] 3. Fichiers vérifiés (qcow2 + XML présents)
[ ] 4. Intégrité qemu-img check: OK
[ ] 5. VM arrêtée (domstate = shut off)
[ ] 6. Disque copié à: ___________________
[ ] 7. Disque restauré validé (qemu-img check OK)
[ ] 8. Définition VM restaurée via virsh define
[ ] 9. VM démarrée (domstate = running)
[ ] 10. Connectivité réseau vérifiée
[ ] 11. Services critiques vérifiés
[ ] 12. Tests applicatifs réussis
[ ] 13. Documentation mise à jour
```

---

## 12. Documentation Post-Restauration

Après restauration réussie, documenter:

**Fichier:** `~/.ssh/qnap_restore_history.log`

```
# Restauration Mint-Infra-Server

## Date: 2026-06-20
## Motif: [Corrige corruption / Update système / Test RTO / Autre]
## Backup utilisé: mint-infra-server_2026-06-20_18-28-05
## Disque cible: /share/InfraData/VMs/Mint-Infra-Server/disk.qcow2
## Durée totale: ~15 min
## Résultat: SUCCESS / PARTIAL / FAILED
## Notes: [détails]

Étapes:
1. Vérification fichiers: ✓
2. Restauration disque: ✓ (4 min)
3. Restauration définition: ✓
4. Démarrage VM: ✓
5. Validation réseau: ✓ (IP 192.168.8.189)
6. Services Docker: ✓ (portainer running)

Problèmes rencontrés: Aucun
Actions futures: Aucune

Opérateur: admin
```

---

## 13. Contacts et Escalade

### 13.1 Points de contact

- **Admin QNAP local:** admin@192.168.8.220
- **Admin infrastructure:** (à remplir)
- **Support QNAP:** support@qnap.com

### 13.2 Escalade

**Niveau 1 (toi):**
- Vérifications de fichiers
- Copie/restauration disque simple
- Démarrage VM

**Niveau 2 (admin infra):**
- Problèmes XML/définition
- Corruption détectée
- Espace disque critique

**Niveau 3 (support QNAP):**
- Erreurs libvirt
- Crash hyperviseur
- Corruption filesystem

---

**Dernière révision:** 2026-06-20
**Version:** 1.0
**Statut:** Production
