# Sauvegarde VM - QNAP Virtualization Station

## Emplacement des sauvegardes

Les exports sont ecrits dans:

- /share/InfraData/03_Backups/02_Linux/01_Backups_VM/

Nommage:

- mint-infra-server_YYYY-MM-DD_HH-MM-SS.qcow2 ou .vdi
- mint-infra-server_YYYY-MM-DD_HH-MM-SS.xml

## Script et planification

- Script source: /share/InfraData/05_Infra/Backups_VM/vm_backup_qnap_host.sh
- Script systeme: /usr/local/sbin/vm_backup_qnap_host.sh
- Cron daily: /etc/cron.daily/vm_backup_qnap_host -> /usr/local/sbin/vm_backup_qnap_host.sh

## Binaires hyperviseur utilises

- VIRSH=/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh
- QEMU_IMG=/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/qemu-img

## Rotation

- Conservation automatique des 7 dernieres sauvegardes
- Suppression des sauvegardes plus anciennes et de leur XML associe
- Parametre: KEEP_LAST=7

## Commandes de test

```sh
/usr/local/sbin/vm_backup_qnap_host.sh
tail -n 80 /var/log/vm_backup_qnap.log
ls -lh /share/InfraData/03_Backups/02_Linux/01_Backups_VM/
```

## Emplacement des logs

- /var/log/vm_backup_qnap.log

### Rotation des logs

- Le log principal est conserve dans /var/log/vm_backup_qnap.log.
- Rotation par taille active via LOG_MAX_BYTES (defaut: 10485760, soit 10 Mo).
- Historique des logs conserve via LOG_KEEP_FILES (defaut: 5):
  - /var/log/vm_backup_qnap.log.1
  - /var/log/vm_backup_qnap.log.2
  - ...
  - /var/log/vm_backup_qnap.log.5

### Indicateurs de run

- Statut du dernier run: /var/lib/vm_backup_qnap/last_run.status
- Statut du dernier run reussi: /var/lib/vm_backup_qnap/last_success.status

Contenu type:

- status=success|failed
- run_ts=YYYY-MM-DD_HH-MM-SS
- run_epoch=...
- vm=...
- resolved_vm=...
- backup_dir=...
- disk=...
- xml=...

## Procedure de restauration si virsh fonctionne

1. Choisir un couple disque + XML du meme horodatage.
2. Restaurer le disque sauvegarde sur l'emplacement cible de la VM, VM arretee.
3. Recharger la definition si necessaire:

```sh
/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh define mint-infra-server_YYYY-MM-DD_HH-MM-SS.xml
```

4. Demarrer la VM:

```sh
/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh start 61a8416a-feb3-4f82-9bb0-a1b4d326f767
```

## Notes d'exploitation

- Sur ce QNAP, le snapshot a chaud est desactive par defaut via ENABLE_HOT_SNAPSHOT=no.
- Raison: la commande snapshot-create-as reste bloquee trop longtemps dans cet environnement.
- Le mode par defaut est donc un export best-effort du disque actif et du XML.
- La VM est resolue via metadata QNAP/libvirt quand le nom lisible ne correspond pas au nom libvirt.

## Etat du dernier test

- Resolution VM via virsh: OK
- Export reel qcow2: OK
- XML de configuration exporte: OK
- Fichiers observes:
  - mint-infra-server_2026-06-20_17-34-30.qcow2
  - mint-infra-server_2026-06-20_17-34-30.xml
  - mint-infra-server_2026-06-20_17-53-09.qcow2
  - mint-infra-server_2026-06-20_17-53-09.xml
- Indicateur de succes run: OK (last_run.status et last_success.status remplis)
- Rotation runtime: non validable sur ce run (2 sauvegardes presentes, il faut depasser 7)
