# Sauvegarde VM - QNAP Virtualization Station

## Emplacement des sauvegardes

Les exports sont ecrits dans:

- /share/InfraData/03_Backups/02_Linux/01_Backups_VM/

Nommage:

- mint-infra-server_YYYY-MM-DD_HH-MM-SS.qcow2 (ou .vdi)
- mint-infra-server_YYYY-MM-DD_HH-MM-SS.xml

## Script et planification

- Script source: /share/InfraData/05_Infra/Backups_VM/vm_backup_qnap_host.sh
- Script systeme: /usr/local/sbin/vm_backup_qnap_host.sh
- Cron daily: /etc/cron.daily/vm_backup_qnap_host -> /usr/local/sbin/vm_backup_qnap_host.sh

## Rotation

- Conservation automatique des 7 dernieres sauvegardes
- Suppression des sauvegardes plus anciennes et de leur XML associe
- Parametre: KEEP_LAST=7 (modifiable)

## Commande de test

```sh
/usr/local/sbin/vm_backup_qnap_host.sh
```

## Emplacement des logs

- /var/log/vm_backup_qnap.log

Lecture rapide:

```sh
tail -n 80 /var/log/vm_backup_qnap.log
```

## Procedure de restauration (libvirt)

1. Choisir un couple fichier disque + XML du meme horodatage.
2. Restaurer le disque de la VM (VM arretee) a partir du .qcow2 ou .vdi sauvegarde.
3. Recharger la definition:

```sh
virsh define mint-infra-server_YYYY-MM-DD_HH-MM-SS.xml
```

4. Demarrer la VM:

```sh
virsh start "Mint-Infra-Server"
```

## Etat actuel sur ce NAS

Test execute le 2026-06-20:

- Installation script: OK
- Lien cron.daily: OK
- Export de test: KO (commande virsh absente dans environnement shell admin)
- Consequence: aucun fichier exporte tant que outil hyperviseur CLI indisponible

Commande de diagnostic prealable:

```sh
command -v virsh
```
