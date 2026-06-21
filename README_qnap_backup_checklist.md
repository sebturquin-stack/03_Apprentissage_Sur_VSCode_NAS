# Checklist Hebdomadaire — Service Sauvegarde VM QNAP

## Objectif

Contrôle rapide (4 commandes, ~60 secondes) de l'état opérationnel du service de sauvegarde VM hébergé sur QNAP.

## Prérequis SSH

```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.8.220
```

## Commande 1 : Vérifier le statut du dernier run

**Objectif:** Confirmer le dernière exécution (succès/échec) avec horodatage et artefacts.

```bash
cat /var/lib/vm_backup_qnap/last_run.status
```

**Résultat attendu:**
status=success
run_ts=2026-06-20_18-28-05
run_epoch=1781972885
vm=Mint-Infra-Server
resolved_vm=61a8416a-feb3-4f82-9bb0-a1b4d326f767
backup_dir=/share/InfraData/03_Backups/02_Linux/01_Backups_VM
disk=/share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.qcow2
xml=/share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.xml
```

**Interprétation:**
- `status=success` → OK
- `status=failed` → Vérifier Commande 3 (log)
- `run_ts` récent (< 1 jour) → OK
- `run_ts` ancien (> 7 jours) → Cron non exécuté ou désactivé

---

## Commande 2 : Vérifier le dernier run réussi

**Objectif:** Identifier la sauvegarde valide la plus récente même en cas d'échec du run courant.

```bash
cat /var/lib/vm_backup_qnap/last_success.status
```

**Résultat attendu:**
```
status=success
run_ts=2026-06-20_18-28-05
...
disk=/share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.qcow2
xml=/share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.xml
```

**Interprétation:**

- Fichier présent et rempli → Au moins 1 sauvegarde valide
- Chemin de `disk` et `xml` existants → Artefacts accessibles
- Horodatage identique à Commande 1 → Dernière exécution a réussi

---

## Commande 3 : Consulter les 80 dernières lignes du log

**Objectif:** Diagnostiquer les erreurs, anomalies, ou blocages en phase d'export/rotation.

```bash
tail -n 80 /var/log/vm_backup_qnap.log
```

**Résultat attendu (dernières lignes):**
```
2026-06-20 18:28:05 [INFO] Debut sauvegarde QNAP hote pour VM: Mint-Infra-Server
2026-06-20 18:28:05 [INFO] run_ts=2026-06-20_18-28-05
2026-06-20 18:28:05 [INFO] VM resolue via virsh: 61a8416a-feb3-4f82-9bb0-a1b4d326f767
2026-06-20 18:28:05 [WARN] Snapshot a chaud desactive (ENABLE_HOT_SNAPSHOT=no). Export best-effort poursuivi.
2026-06-20 18:30:55 [INFO] Export termine: /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.qcow2 + .xml
2026-06-20 18:30:55 [INFO] Sauvegarde terminee avec succes.
```

**Interprétation:**

- Bloc `[INFO] Debut sauvegarde ... [INFO] Sauvegarde terminee avec succes` → OK
- `[WARN] Snapshot a chaud desactive` → Normal, mode best-effort
- `[ERROR]` → Investiguer (voir ci-dessous)
- `[INFO] Rotation: suppression ...` → Rotation active, archivage ancien jeu

**Diagnostics courants:**

| Log                            | Cause                  | Action                                  |
|--------------------------------|------------------------|-----------------------------------------|
| `VM resolue via virsh: (vide)` | VM introuvable         | Vérifier virsh list --all               |
| `Export termine:` absent       | Export bloqué > 30 min | Tuer run en cours, redémarrer VM        |
| `[ERROR]` avec code non-zéro   | Script interne         | Consulter admin local                   |
| Pas de log récent              | Cron non exécuté       | Vérifier /etc/cron.daily/vm_backup_qnap |

---

## Commande 4 : Vérifier les sauvegardes et rotation

**Objectif:** Confirmer la présence des artefacts, le nombre conservé, et la rotation en action.

```bash
ls -lh /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_*.qcow2 && echo "---" && \
echo "Nombre de sauvegardes:" && \
ls -1 /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_*.qcow2 | wc -l && echo "---" && \
du -sh /share/InfraData/03_Backups/02_Linux/01_Backups_VM/
```

**Résultat attendu:**
```
-rw-r--r--  1 root root 12G 2026-06-20 18:21 /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-21-00.qcow2
-rw-r--r--  1 root root 12G 2026-06-20 18:28 /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_2026-06-20_18-28-05.qcow2
---
Nombre de sauvegardes:
2
---
25G     /share/InfraData/03_Backups/02_Linux/01_Backups_VM/
```

**Interprétation:**

- Nombre ≤ 7 → OK (politique KEEP_LAST=7)
- Nombre > 7 → Rotation cassée, investiguer
- Taille par fichier ~12G → Normal pour cette VM
- Taille totale croissante → Sauvegardes s'accumulent, rotation fonctionne
- Taille stable (semaine à semaine) → Rotation valide, espace maîtrisé

---

## Checklist Rapide (Lecture 60s)

| # | Commande                                           | Critère de succès                      | Alerte                                    |
|---|----------------------------------------------------|----------------------------------------|-------------------------------------------|
| 1 | `cat /var/lib/vm_backup_qnap/last_run.status`      | status=success, run_ts récent          | status=failed ou run_ts > 7j              |
| 2 | `cat /var/lib/vm_backup_qnap/last_success.status`  | Fichier présent, chemins valides       | Fichier absent ou ancien                  |
| 3 | `tail -n 80 /var/log/vm_backup_qnap.log`           | Fin: "Sauvegarde terminee avec succes" | [ERROR], export bloqué, pas de log récent |
| 4 | `ls -lh ... && echo Nombre: $(ls -1 ... \| wc -l)` | Nombre ≤ 7, taille croissante hebdo    | Nombre > 7, espace stable ou décroissant  |

---

## Dépannage Rapide

### Le dernier run a échoué (status=failed)

1. Consulter le log (Commande 3) pour identifier le bloc `[ERROR]`.
2. Vérifier la VM:
   ```bash
   /share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh list --all
   /share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh dominfo 61a8416a-feb3-4f82-9bb0-a1b4d326f767
   ```
3. Tester un run manuel:
   ```bash
   /usr/local/sbin/vm_backup_qnap_host.sh
   ```

### Le nombre de sauvegardes dépasse 7

1. Vérifier le log (Commande 3): chercher `[INFO] Rotation: suppression`.
2. Si absent, rotation cassée. Vérifier manuelle:
   ```bash
   ls -1tr /share/InfraData/03_Backups/02_Linux/01_Backups_VM/mint-infra-server_*.qcow2 | head -n -7 | xargs rm -f
   ```
3. Relancer le script:
   ```bash
   /usr/local/sbin/vm_backup_qnap_host.sh
   ```

### Le log grandit trop (> 100 Mo)

Rotation des logs est active par défaut. Vérifier:
```bash
ls -lh /var/log/vm_backup_qnap.log*
```

Doit voir:

- vm_backup_qnap.log
- vm_backup_qnap.log.1 (archive compressée si > 10 Mo)
- ... vm_backup_qnap.log.5

Si > 5 fichiers, rotation est cassée. Nettoyer:
```bash
rm -f /var/log/vm_backup_qnap.log.* && truncate -s 0 /var/log/vm_backup_qnap.log
```

---

## Fréquence Recommandée

- **Quotidienne (réflexe)**: Une seule ligne rapide:
  ```bash
  grep "status=" /var/lib/vm_backup_qnap/last_run.status
  ```

- **Hebdomadaire (4 commandes complètes)**: Samedi ou lundi, quelques minutes.

- **Mensuelle (révision)**: Consulter la taille totale, ajuster KEEP_LAST si besoin.

---

## Fichiers et Ressources

- **Script principal**: /usr/local/sbin/vm_backup_qnap_host.sh
- **Source (NAS)**: /share/InfraData/05_Infra/Backups_VM/vm_backup_qnap_host.sh
- **Sauvegardes**: /share/InfraData/03_Backups/02_Linux/01_Backups_VM/
- **Logs**: /var/log/vm_backup_qnap.log
- **Statuts**: /var/lib/vm_backup_qnap/last_run.status, last_success.status
- **Cron quotidien**: /etc/cron.daily/vm_backup_qnap_host
- **Documentation**: /share/InfraData/05_Infra/Backups_VM/README.md

---

**Dernière révision**: 2026-06-20
