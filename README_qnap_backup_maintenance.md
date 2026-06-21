# Plan de Maintenance — Service Sauvegarde VM QNAP

## Vue d'ensemble

Ce document définit les tâches de maintenance systématique du service de sauvegarde VM hébergé sur QNAP Virtualization Station. L'objectif est d'assurer la disponibilité, la fiabilité et la durabilité des sauvegardes.

**Calendrier d'exécution:**

- Quotidienne (automnal)
- Hebdomadaire (manuel)
- Mensuelle (manuel)
- Trimestrielle (manuel)

---

## 1. Tâches Quotidiennes

### 1.1 Vérification automatique (réflexe 30s)

**Fréquence:** Tous les matins ou juste avant intervention critique sur VM

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'grep "status=" /var/lib/vm_backup_qnap/last_run.status'
```

**Résultat attendu:**
```
status=success
```

**Action si déviation:**
- `status=failed` → Consulter Commande 3 de la checklist (log tail 80)
- Fichier absent → Cron non exécuté, voir **Gestion des erreurs**
- `run_ts` > 1 jour → Vérifier cron.daily

### 1.2 Surveillance du statut du dernier succès

**Fréquence:** Une fois par jour (si status=success le jour précédent)

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'cat /var/lib/vm_backup_qnap/last_success.status | head -n 3'
```

**Résultat attendu:**
```
status=success
run_ts=2026-06-20_18-28-05
run_epoch=1781972885
```

**Alerte si:**
- `run_ts` n'a pas changé depuis > 3 jours
- Fichier absent ou corrompu

---

## 2. Tâches Hebdomadaires

### 2.1 Audit complet (checklist 4 commandes, ~5 min)

**Fréquence:** Une fois par semaine, idéalement le samedi ou lundi

**Utiliser:** [README_qnap_backup_checklist.md](README_qnap_backup_checklist.md)

Exécuter toutes les 4 commandes et remplir le tableau récapitulatif:

| # | Commande | ✓ | Remarque |
|---|----------|---|----------|
| 1 | last_run.status | [ ] | |
| 2 | last_success.status | [ ] | |
| 3 | tail -n 80 log | [ ] | |
| 4 | ls + nombre + du -sh | [ ] | |

### 2.2 Vérification du log pour anomalies récentes

**Fréquence:** Une fois par semaine

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'grep -E "\[ERROR\]|\[FATAL\]" /var/log/vm_backup_qnap.log | tail -n 20'
```

**Résultat attendu:**
```
(empty, aucune erreur)
```

**Si erreurs détectées:**
- Noter le timestamp et le message
- Consulter la section **Gestion des erreurs**

### 2.3 Vérification de la rotation (compte des sauvegardes)

**Fréquence:** Une fois par semaine

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'BK="/share/InfraData/03_Backups/02_Linux/01_Backups_VM"; \
   echo "Nombre: $(ls -1 $BK/mint-infra-server_*.qcow2 2>/dev/null | wc -l)"; \
   echo "Taille: $(du -sh $BK/ | cut -f1)"; \
   ls -lh $BK/mint-infra-server_*.qcow2 | tail -n 3'
```

**Résultat attendu:**
```
Nombre: 2 à 7
Taille: 24G à 84G (2-7 × ~12G)
-rw-r--r-- ... mint-infra-server_2026-06-20_18-21-00.qcow2
-rw-r--r-- ... mint-infra-server_2026-06-20_18-28-05.qcow2
```

**Alerte si:**
- Nombre > 7 → Rotation défaillante, voir **Procédure en cas de manque d'espace**
- Nombre constant pendant 2 semaines → Cron non exécuté ou VM arrêtée
- Taille en décroissance → Ancien backup supprimé manuellement, vérifier intégrité

### 2.4 Vérification de la taille du log

**Fréquence:** Une fois par semaine

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'ls -lh /var/log/vm_backup_qnap.log*'
```

**Résultat attendu:**
```
-rw-r--r-- 1 root root 2.3M 2026-06-20 18:30 /var/log/vm_backup_qnap.log
-rw-r--r-- 1 root root 9.8M 2026-06-18 02:15 /var/log/vm_backup_qnap.log.1
```

**Alerte si:**
- vm_backup_qnap.log > 20M → Rotation des logs cassée
- Plus de 5 fichiers `.log.*` → Nettoyage manuel requis
- Absence de fichiers `.log.*` → Rotation ne s'est jamais déclenchée

---

## 3. Tâches Mensuelles

### 3.1 Audit de sauvegarde par test de restauration (optionnel, recommandé)

**Fréquence:** Une fois par mois (ou tous les 2 mois si CPU VM critique)

**Objectif:** Vérifier que les fichiers sont intacts et restaurables.

**Prérequis:**
- Machine de test ou VM de backup disponible
- Espace disque suffisant pour copier 1 qcow2 (~12G)

**Procédure:**
1. Choisir le backup le plus récent:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'ls -tr /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_*.qcow2 | tail -n 1'
   ```

2. Vérifier l'intégrité du fichier qcow2:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     '/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/qemu-img check -r all <FILE.qcow2>'
   ```

3. Copier le XML pour documentation:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'cat /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_*.xml | tail -n 1'
   ```

4. Documenter le résultat:
   - Date du test
   - Fichier testé
   - Résultat du qemu-img check
   - Acceptation / Rejet

**Résultat attendu:**
```
No errors were found on the image.
```

### 3.2 Révision des paramètres de rotation

**Fréquence:** Une fois par mois

**Objectif:** Vérifier que KEEP_LAST=7 est approprié selon la croissance observée.

**Checklist:**
- [ ] Calculer la taille moyenne d'un backup: (taille_totale / nombre_backups)
- [ ] Estimer la rétention en jours: (nombre_backups / runs_par_jour)
- [ ] Vérifier que l'espace disque n'approche pas de 90%
- [ ] Ajuster KEEP_LAST si besoin

**Exemple calcul:**
```
Taille totale: 25G
Nombre de backups: 2
Taille moyenne: 12.5G
Rétention avec KEEP_LAST=7: 7 × 12.5G = 87.5G
Espace utilisé / disponible: (87.5G / 500G) = 17.5% → OK
```

**Action si espace utilisé > 60%:**
- Réduire KEEP_LAST (ex: de 7 à 5)
- Nettoyer manuellement les backups obsolètes
- Consulter **Procédure en cas de manque d'espace**

### 3.3 Audit des logs accumulés

**Fréquence:** Une fois par mois

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'du -sh /var/log/vm_backup_qnap.log* && \
   echo "---" && \
   ls -1 /var/log/vm_backup_qnap.log* | wc -l && echo "fichiers"'
```

**Résultat attendu:**
```
12M     /var/log/vm_backup_qnap.log*
6
fichiers
```

**Action si > 50M total:**
- Archiver les logs anciens:
  ```bash
  ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
    'tar czf /var/log/vm_backup_qnap_archive_$(date +%Y%m%d).tar.gz /var/log/vm_backup_qnap.log.*'
  ```
- Nettoyer:
  ```bash
  ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
    'rm -f /var/log/vm_backup_qnap.log.{3..99}'
  ```

### 3.4 Synchronisation de la documentation

**Fréquence:** Une fois par mois

**Objectif:** S'assurer que la source locale et le NAS sont en phase.

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'md5sum /usr/local/sbin/vm_backup_qnap_host.sh /share/InfraData/05_Infra/Backups_VM/vm_backup_qnap_host.sh'
```

**Résultat attendu:**
```
<HASH1> /usr/local/sbin/vm_backup_qnap_host.sh
<HASH1> /share/InfraData/05_Infra/Backups_VM/vm_backup_qnap_host.sh
```

**Si HASH différents:**
- Identifier quelle version est à jour
- Redéployer depuis source:
  ```bash
  ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
    'cp /share/InfraData/05_Infra/Backups_VM/vm_backup_qnap_host.sh /usr/local/sbin/vm_backup_qnap_host.sh && \
     chmod 750 /usr/local/sbin/vm_backup_qnap_host.sh && \
     echo OK'
  ```

---

## 4. Tâches Trimestrielles

### 4.1 Audit complet d'infrastructure

**Fréquence:** Tous les 3 mois

**Objectif:** Vérifier l'architecture globale, les dépendances et les chemins critiques.

**Checklist:**

- [ ] **VM cible**
  - VM Mint-Infra-Server toujours présente ?
  ```bash
  virsh list --all | grep Mint
  ```
  - UUID = 61a8416a-feb3-4f82-9bb0-a1b4d326f767 toujours valide ?

- [ ] **Chemins QNAP**
  - virsh accessible: `/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh` ?
  - qemu-img accessible: `/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/qemu-img` ?
  - Répertoires de backup accessibles en écriture ?

- [ ] **Permissions**
  - /usr/local/sbin/vm_backup_qnap_host.sh exécutable (750) ?
  - /share/InfraData/03_Backups/02_Linux/01_Backups_VM/ writable ?
  - /var/lib/vm_backup_qnap/ accessible ?

- [ ] **Cron**
  - /etc/cron.daily/vm_backup_qnap_host existe et pointe correctement ?
  - Cron daemon actif sur le QNAP ?

- [ ] **Espace disque**
  - Espace disque QNAP > 100G libre ?
  - Croissance des backups < 100G/trimestre ?

- [ ] **Dépendances externes**
  - Accès SSH NAS depuis workstation OK ?
  - Clé SSH ~/id_ed25519 valide et protégée (600) ?
  - NAS reachable et stable sur 192.168.8.220 ?

### 4.2 Test de scénario de récupération (RTO/RPO)

**Fréquence:** Une fois par trimestre

**Objectif:** Vérifier que la récupération est possible dans les délais acceptables.

**Scénario 1: Restauration rapide (< 30 min)**
```bash
# 1. Obtenir le fichier le plus récent
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'ls -tr /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_*.qcow2 | tail -n 1'

# 2. Noter le chemin
# 3. Simuler : "Si VM disparaît, je peux restaurer depuis ce fichier en < 30 min ?"
```

**Scénario 2: Vérification de sauvegarde aléatoire (1 backup tous les 3 mois)**
```bash
# 1. Choisir un backup au hasard
# 2. Vérifier qemu-img check
# 3. Copier le XML localement
# 4. Documenter le résultat
```

**Documentation requise après test:**
- Date du test
- Fichier testé
- Résultat du qemu-img check
- Feedback opérationnel
- Ajustements requis

### 4.3 Révision de la documentation

**Fréquence:** Une fois par trimestre

**Objectif:** Mettre à jour les README, chemins, et procédures selon la réalité observée.

**Checklist:**
- [ ] README.md reflète les chemins actuels ?
- [ ] README_qnap_backup_checklist.md au date ?
- [ ] README_qnap_backup_maintenance.md (ce fichier) toujours valide ?
- [ ] Aucune étape obsolète ou cassée ?
- [ ] Contact admin actualisé (email/Slack) ?

### 4.4 Nettoyage des archives anciennes

**Fréquence:** Une fois par trimestre

**Objectif:** Archiver et purger les logs/rapports très anciens.

**Commande:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'find /var/log/vm_backup_qnap_archive_*.tar.gz -mtime +90 -delete'
```

---

## 5. Surveillance des Logs

### 5.1 Emplacements des logs

- **Log principal:** `/var/log/vm_backup_qnap.log`
- **Archives:** `/var/log/vm_backup_qnap.log.1` à `.5` (rotation par taille)
- **Archives comprimées (trimestrielles):** `/var/log/vm_backup_qnap_archive_*.tar.gz`

### 5.2 Format du log

Chaque exécution produit un bloc d'entrée:
```
2026-06-20 18:28:05 [INFO] Debut sauvegarde QNAP hote pour VM: Mint-Infra-Server
2026-06-20 18:28:05 [INFO] run_ts=2026-06-20_18-28-05
2026-06-20 18:28:05 [INFO] VM resolue via virsh: 61a8416a-feb3-4f82-9bb0-a1b4d326f767
2026-06-20 18:28:05 [WARN] Snapshot a chaud desactive (ENABLE_HOT_SNAPSHOT=no). Export best-effort poursuivi.
2026-06-20 18:30:55 [INFO] Export termine: ... + ...
2026-06-20 18:30:55 [INFO] Sauvegarde terminee avec succes.
```

Niveaux utilisés:
- `[INFO]` : opération normale
- `[WARN]` : comportement dégradé mais fonctionnel
- `[ERROR]` : tentative échouée
- `[FATAL]` : script arrêté sans completion

### 5.3 Filtres utiles

**Erreurs récentes:**
```bash
tail -n 500 /var/log/vm_backup_qnap.log | grep "\[ERROR\]"
```

**Rotations effectuées:**
```bash
tail -n 500 /var/log/vm_backup_qnap.log | grep "Rotation: suppression"
```

**Exports qui ont pris longtemps (> 5 min):**
```bash
grep "Export termine" /var/log/vm_backup_qnap.log | awk -F'[: ]' '
  NR==1 {start=$1":"$2":"$3; start_sec = $1*3600 + $2*60 + $3}
  NR>1 {
    end=$1":"$2":"$3; end_sec = $1*3600 + $2*60 + $3
    diff = end_sec - start_sec
    if (diff > 300) print $0 " [LONG: " diff "s]"
  }
'
```

---

## 6. Surveillance des Fichiers d'État

### 6.1 Fichiers de statut

**Chemin:** `/var/lib/vm_backup_qnap/`

- `last_run.status` : État du dernier lancement (succès/échec)
- `last_success.status` : État du dernier succès confirmé

### 6.2 Contenu typique

```
status=success
run_ts=2026-06-20_18-28-05
run_epoch=1781972885
vm=Mint-Infra-Server
resolved_vm=61a8416a-feb3-4f82-9bb0-a1b4d326f767
backup_dir=/share/InfraData/03_Backups/02_Linux/01_Backups_VM
disk=/share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.qcow2
xml=/share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.xml
```

### 6.3 Vérification périodique

**Quotidienne (30s):**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'grep status /var/lib/vm_backup_qnap/last_run.status && \
   [ "$(stat -c%Y /var/lib/vm_backup_qnap/last_run.status)" -gt "$(($(date +%s) - 86400))" ] && echo "RECENT" || echo "STALE"'
```

**Hebdomadaire (audit complet):**
Voir section **2.1 Audit complet**

---

## 7. Surveillance de la Rotation

### 7.1 Comportement attendu

- **Fréquence:** À chaque run script (quotidiennement via cron)
- **Politique:** KEEP_LAST=7 (conservation des 7 derniers jeux)
- **Artefacts supprimés:** Les paires (disque + XML) les plus anciennes quand compteur > 7

### 7.2 Vérification mensuelle

```bash
# Compter les backups
BK="/share/InfraData/03_Backups/02_Linux/01_Backups_VM"
COUNT=$(ls -1 $BK/mint-infra-server_*.qcow2 2>/dev/null | wc -l)
echo "Nombre de backups: $COUNT"

# Alerter si > 7
if [ $COUNT -gt 7 ]; then
  echo "ALERTE: Nombre > 7, rotation cassée !"
  exit 1
fi

# Afficher la liste triée
echo "Ordre de conservation:"
ls -1tr $BK/mint-infra-server_*.qcow2 | tail -n $COUNT
```

### 7.3 Test de rotation forcée (tous les 3 mois)

Voir section **4.2 Test de scénario de récupération**

---

## 8. Gestion des Erreurs

### 8.1 Erreur : VM introuvable

**Symptôme dans log:**
```
[ERROR] VM resolue via virsh: (vide)
```

**Diagnostic:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  '/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh list --all | grep -i mint'
```

**Causes possibles:**
- VM arrêtée (OK, script devrait continuer)
- VM supprimée (KO, script échouera)
- virsh en erreur / permissions insuffisantes

**Actions:**
1. Redémarrer virsh:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'systemctl restart libvirtd'
   ```
2. Relancer script:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     '/usr/local/sbin/vm_backup_qnap_host.sh'
   ```
3. Si toujours en erreur, contacter admin QNAP

### 8.2 Erreur : Export disque bloqué (> 10 min)

**Symptôme:**
```
Script exécution prend anormalement longtemps (> 30 min au lieu de ~5 min)
```

**Diagnostic:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'ps aux | grep qemu-img | grep -v grep'
```

**Causes possibles:**
- VM très active (I/O CPU saturée)
- NAS chargé (backups réseau parallèles)
- Disque source fragmenté ou lent

**Actions:**
1. Vérifier la charge QNAP:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 'top -bn1 | head -n 5'
   ```

2. Si charge < 50%, relancer export une fois:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     '/usr/local/sbin/vm_backup_qnap_host.sh'
   ```

3. Si blocage persiste, tuer et nettoyer:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'pkill -f "qemu-img copy" || true; \
      pkill -f "virsh" || true; \
      sleep 5; \
      rm -f /tmp/vm_backup_*.tmp'
   ```

4. Redémarrer le service:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'systemctl restart libvirtd'
   ```

### 8.3 Erreur : Cron non exécuté

**Symptôme:**
```
last_run.status n'a pas changé depuis > 3 jours
```

**Diagnostic:**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'ls -l /etc/cron.daily/vm_backup_qnap_host && \
   [ -x /usr/local/sbin/vm_backup_qnap_host.sh ] && echo "Script OK" || echo "Script KO"'
```

**Causes possibles:**
- Cron daemon arrêté
- Lien symbolique cassé
- Script non exécutable

**Actions:**
1. Vérifier cron daemon:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'ps aux | grep cron'
   ```

2. Redémarrer cron:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'systemctl restart cron'
   ```

3. Recréer le lien symbolique:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'ln -sfn /usr/local/sbin/vm_backup_qnap_host.sh /etc/cron.daily/vm_backup_qnap_host && \
      chmod 750 /usr/local/sbin/vm_backup_qnap_host.sh && \
      echo OK'
   ```

4. Tester manuellement:
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     '/usr/local/sbin/vm_backup_qnap_host.sh && echo "Test OK"'
   ```

---

## 9. Procédure en Cas d'Échec

### 9.1 Diagnostic initial (5 min)

**Étape 1: Vérifier le statut**
```bash
cat /var/lib/vm_backup_qnap/last_run.status | grep status
```

**Étape 2: Consulter le log des dernières 100 lignes**
```bash
tail -n 100 /var/log/vm_backup_qnap.log | grep -E "\[ERROR\]|\[FATAL\]|Export|VM resolue"
```

**Étape 3: Identifier l'étape d'échec**
- VM non résolue → section **8.1**
- Export bloqué → section **8.2**
- Autre → section **8.3 ou ci-dessous**

### 9.2 Procédure complète d'intervention

**Prérequis:** SSH access en tant qu'admin@192.168.8.220

**Étape 1: Arrêter tout processus orphelin**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'pkill -f vm_backup_qnap_host 2>/dev/null || true; \
   pkill -f qemu-img 2>/dev/null || true; \
   sleep 3; \
   ps aux | grep -i backup'
```

**Étape 2: Vérifier l'intégrité des fichiers**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'ls -l /var/lib/vm_backup_qnap/ /usr/local/sbin/vm_backup_qnap_host.sh'
```

**Étape 3: Vérifier l'espace disque**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'df -h /share | head -n 2'
```

**Étape 4: Redémarrer le service de virtualisation (optionnel, disruptif)**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'systemctl restart libvirtd; sleep 5; echo OK'
```

**Étape 5: Relancer le script**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  '/usr/local/sbin/vm_backup_qnap_host.sh'
```

**Étape 6: Attendre et vérifier**
```bash
# Attendre 5 min
sleep 300

# Vérifier le statut
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'cat /var/lib/vm_backup_qnap/last_run.status | grep status'
```

**Étape 7: Escalade si toujours en erreur**
- Consulter les logs complets
- Contacter l'admin QNAP ou le support
- Créer un ticket avec les détails du log

---

## 10. Procédure en Cas de Corruption

### 10.1 Symptômes

- Fichier qcow2 inaccessible ou non valide
- Erreur lors de qemu-img check
- Impossible de restaurer depuis le backup

### 10.2 Diagnostic

**Étape 1: Vérifier le fichier soupçonné**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'BK="/share/InfraData/03_Backups/02_Linux/01_Backups_VM"; \
   FILE=$BK/mint-infra-server_2026-06-20_18-28-05.qcow2; \
   /share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/qemu-img check -r all "$FILE"'
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

### 10.3 Action en cas de corruption

**Option 1: Utiliser un backup plus ancien (recommandé)**
```bash
# Lister tous les backups
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'ls -ltr /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_*.qcow2'

# Choisir le 2e ou 3e plus récent (probablement sain)
# Procéder à la restauration depuis ce fichier
```

**Option 2: Supprimer le fichier corrompu et le remplacer**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'BK="/share/InfraData/03_Backups/02_Linux/01_Backups_VM"; \
   FILE=$BK/mint-infra-server_2026-06-20_18-28-05; \
   rm -f "$FILE.qcow2" "$FILE.xml"; \
   echo "Fichiers corrompu supprimés"'

# Relancer un backup immédiat
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  '/usr/local/sbin/vm_backup_qnap_host.sh'
```

**Option 3: Enquête approfondie (pour développeur)**
```bash
# Sauvegarder le fichier corrompu pour analyse
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'cp /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.qcow2 \
      /share/InfraData/03_Backups/02_Linux/01_Backups_VM/.corrupted_backup_for_analysis.qcow2'

# Contacter l'admin système avec le fichier pour analyse
```

---

## 11. Procédure en Cas de Manque d'Espace

### 11.1 Symptômes

- `df -h /share` indique > 85% utilisé
- Échec d'export avec message "No space left on device"
- Nouvelle rotation refuse les suppressions

### 11.2 Diagnostic rapide

```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'df -h /share | tail -n 1; \
   du -sh /share/InfraData/03_Backups/02_Linux/01_Backups_VM/'
```

**Résultat interprétation:**
```
/dev/xxx     1.0T  880G  120G  88%  /share
---
88G     /share/InfraData/03_Backups/02_Linux/01_Backups_VM/
```

Backups utilisent ~10% de l'espace total (OK si < 50%).

### 11.3 Actions graduelles

**Action 1: Réduction immédiate (KEEP_LAST = 5)**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'sed -i "s/KEEP_LAST=7/KEEP_LAST=5/" /usr/local/sbin/vm_backup_qnap_host.sh && \
   /usr/local/sbin/vm_backup_qnap_host.sh && \
   echo "Script relancé avec KEEP_LAST=5"'
```

**Action 2: Nettoyage manuel des anciens backups**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'BK="/share/InfraData/03_Backups/02_Linux/01_Backups_VM"; \
   # Conserver seulement les 3 plus récents
   ls -1tr $BK/mint-infra-server_*.qcow2 | head -n -3 | xargs rm -f; \
   ls -1tr $BK/mint-infra-server_*.xml | head -n -3 | xargs rm -f; \
   echo "Ancien backups supprimés"; \
   du -sh $BK/'
```

**Action 3: Déplacer les backups obsolètes vers archive externe (si disponible)**
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'BK="/share/InfraData/03_Backups/02_Linux/01_Backups_VM"; \
   ARCHIVE="/share/InfraData/03_Backups/02_Linux/02_Archive/"; \
   mkdir -p "$ARCHIVE"; \
   # Déplacer les backups de plus de 30 jours
   find $BK -name "mint-infra-server_*.qcow2" -mtime +30 -exec mv {} "$ARCHIVE" \; ; \
   echo "Ancien backups archivés"'
```

**Action 4: Augmenter l'espace physique (long terme)**
- Ajouter un disque au QNAP
- Étendre la partition /share
- Contacte l'admin infrastructure

### 11.4 Prévention

Vérifier mensuellement:
```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
  'df /share | tail -n 1 | awk "{if (\$5 > 80) print \"ALERTE ESPACE: \" \$5}"'
```

---

## 12. Bonnes Pratiques QNAP

### 12.1 Configuration système

1. **Vérifier la date/heure du QNAP**
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 'date'
   ```
   Doit être proche de la date réelle (± 1 min).

2. **Vérifier la résolution DNS**
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 'nslookup google.com'
   ```

3. **Vérifier les montages NFS/SMB si utilisés**
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 'mount | grep share'
   ```

### 12.2 Optimisation des performances

1. **Vérifier la charge CPU et RAM**
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 'top -bn1 | head -n 10'
   ```
   Idéalement < 50% avant un backup.

2. **Planifier les backups hors des heures de pointe**
   - Actuellement: quotidien via cron.daily (exécution variable)
   - Si charge élevée, considérer un horaire fixe en off-peak

3. **Vérifier la fragmentation du disque**
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'df -i /share | tail -n 1'
   ```
   Si inodes > 95%, contacter admin.

### 12.3 Sécurité

1. **Vérifier les permissions des fichiers sensibles**
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'ls -l /usr/local/sbin/vm_backup_qnap_host.sh'
   ```
   Doit être 750 (rwxr-x---).

2. **Vérifier les accès à la clé SSH locale**
   ```bash
   ls -l ~/.ssh/id_ed25519
   ```
   Doit être 600 (-rw-------).

3. **Chiffrer les backups si données sensibles**
   - Considérer LUKS ou gpg
   - Pas implémenté actuellement, ajouter si nécessaire

### 12.4 Maintenance du hyperviseur

1. **Redémarrage préventif du libvirtd (trimestriel)**
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'systemctl restart libvirtd; sleep 5; echo OK'
   ```

2. **Vérifier la version QKVM**
   ```bash
   ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220 \
     'ls /share/CACHEDEV1_DATA/.qpkg/QKVM/'
   ```

3. **Mise à jour firmware QNAP**
   - Consulter interface de gestion QNAP
   - Planifier pendant maintenance

---

## 13. Calendrier Synthétique

| Période | Tâche | Durée | Outil |
|---------|-------|-------|-------|
| Quotidienne | Vérifier status | 30s | 1 ligne shell |
| Hebdomadaire (samedi) | Audit 4 commandes | 5 min | Checklist |
| Mensuelle | Test restore, paramètres, nettoyage logs | 30 min | Manuel |
| Trimestrielle | Audit infra, test RTO/RPO, doc | 1-2h | Complet |

---

## 14. Contacts et Escalade

### 14.1 Points de contact

- **Admin QNAP local:** admin@192.168.8.220
- **Admin infrastructure:** (à remplir selon votre setup)
- **Support QNAP:** support@qnap.com (si sous contrat)
- **Documentation:** Ce fichier + README.md + checklist.md

### 14.2 Escalade

**Niveau 1 (toi):**
- Diagnostics basiques
- Relance de scripts
- Vérification des chemins

**Niveau 2 (admin infra):**
- Problèmes de permissions
- Restauration depuis backup
- Redémarrage de services critiques

**Niveau 3 (support QNAP):**
- Crash hyperviseur
- Corruption filesystem
- Erreurs matériel

---

**Dernière révision:** 2026-06-20
**Version:** 1.0
**Statut:** Production
