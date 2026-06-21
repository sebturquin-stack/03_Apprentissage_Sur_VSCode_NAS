# Runbook Admin - Portainer

## Objet

Ce runbook admin sert a verifier, exploiter et depanner Portainer dans l'infrastructure SebNet-LAN-2.5G sans toucher au guide d'installation initial.

Contexte:

- service: Portainer CE
- VM cible: `mint-infra-server`
- dossier physique: `/opt/portainer`
- dossier logique: `/InfraData/05_Infra/01_Monitoring/02_Portainer`
- acces HTTPS: `https://mint-infra-server:9443`

## Etat Attendu

Portainer est considere operationnel si:

- le conteneur est `Up` dans `docker compose ps`;
- le port `9443` repond sur le LAN;
- l'URL HTTPS retourne une page Portainer;
- aucun crash en boucle n'apparait dans les logs;
- le compte admin initial a ete cree.

Important:

- Portainer n'affiche pas forcement `healthy`.
- Un statut `Up` est normal si aucun healthcheck n'est defini dans l'image.

## Verification Rapide

### 1. Verifier le conteneur

```bash
cd /opt/portainer
sudo docker compose ps
```

Attendu:

- conteneur `portainer` en statut `Up`
- port `9443` publie

### 2. Verifier l'ecoute HTTPS depuis la VM

```bash
curl -k -I https://localhost:9443
```

Attendu:

- reponse HTTP valide, typiquement `200 OK`

### 3. Verifier l'acces LAN

Depuis une machine du LAN:

```powershell
curl.exe -k -I https://192.168.8.189:9443
```

Attendu:

- `HTTP/1.1 200 OK`

### 4. Verifier les logs recents

```bash
sudo docker logs portainer --tail 50
```

Attendu:

- demarrage HTTPS sur `:9443`
- absence de boucle de redemarrage
- absence d'erreurs fatales

## Analyse Des Logs De Premiere Installation

Les messages suivants sont normaux au premier lancement:

- `encryption key file not present`
- `proceeding without encryption key`
- `no cert files found, generating self signed SSL certificates`
- `starting HTTPS server | bind_address=:9443`

Interpretation:

- absence de cle de chiffrement persistante: acceptable en premier jet, ameliorable;
- certificat auto-signe: normal en installation initiale;
- serveur HTTPS demarre: attendu;
- base Portainer creee ou chargee: attendu.

## Cas Particulier: Timeout De Securite Initial

Si le log contient:

- `the Portainer instance timed out for security purposes`

Interpretation:

- le compte admin n'a pas ete initialise a temps au premier lancement;
- Portainer se protege en gelant l'instance tant que l'initialisation n'est pas finalisee.

Procedure:

```bash
cd /opt/portainer
sudo docker compose restart
sudo docker compose ps
```

Puis:

- ouvrir rapidement `https://mint-infra-server:9443`
- accepter le certificat auto-signe
- creer le compte admin

## Commandes D'Exploitation Courante

### Statut

```bash
cd /opt/portainer
sudo docker compose ps
```

### Logs

```bash
sudo docker compose logs --tail 100
```

### Redemarrage

```bash
cd /opt/portainer
sudo docker compose restart
```

### Arret / Demarrage

```bash
cd /opt/portainer
sudo docker compose down
sudo docker compose up -d
```

### Mise a jour de l'image

```bash
cd /opt/portainer
sudo docker compose pull
sudo docker compose up -d
```

## Points De Controle Admin

### Reseau

- le port `9443` doit rester reserve au LAN;
- le port `8000` ne doit pas etre expose inutilement a l'exterieur;
- le port `9000` n'est pas mappe dans le compose actuel, ce qui est correct.

### Persistance

- le volume `portainer_data` doit exister;
- il contient la base Portainer et les donnees d'etat.

Commande:

```bash
sudo docker volume ls | grep portainer
```

### Isolation

- Portainer ne doit pas casser Netdata;
- Portainer ne depend pas du NAS pour son runtime;
- le runtime local dans `/opt/portainer` est conforme a la logique structurelle definie.

## Durcissement Niveau 2 (Applique)

### 1. Version image figee

Etat final:

- `portainer/portainer-ce:2.39.3`

### 2. Cle de chiffrement persistante active

Etat final:

- secret present: `/opt/portainer/secrets/portainer`;
- secret monte dans compose via `secrets:`;
- base chargee en mode chiffre (`portainer.edb`).

### 3. TLS personnalise actif

Etat final:

- certificat local dedie: `/opt/portainer/certs/portainer.crt`;
- cle privee: `/opt/portainer/certs/portainer.key`;
- lancement Portainer avec `--tlscert` et `--tlskey`;
- certificat presente un sujet explicite `CN=mint-infra-server`.

### 4. Sauvegarde reguliere activee

Etat final:

- script: `/usr/local/sbin/backup_portainer_data.sh`;
- planification: `/etc/cron.d/portainer-backup`;
- periodicite: tous les jours a `02:30`;
- retention: suppression auto des archives de plus de 14 jours;
- test manuel effectue avec archive generee dans `/opt/portainer/backups`.

## Niveau 3 Allege (Applique)

### Objectif

- augmenter la resilience sans complexifier l'exploitation quotidienne.

### 1. Export backup vers NAS

Etat final:

- script actif: `/usr/local/sbin/portainer_backup_to_nas.sh`;
- source locale: `/opt/portainer/backups`;
- destination NAS: `/InfraData/05_Infra/01_Monitoring/02_Portainer/99_Backups`;
- checksum SHA256 generee pour chaque archive copiee;
- retention NAS: suppression des archives de plus de 30 jours.

### 2. Test de restauration simple (non destructif)

Etat final:

- script actif: `/usr/local/sbin/portainer_restore_smoke_test.sh`;
- verification checksum si presente;
- verification archive via `tar -tzf`;
- aucune ecriture dans le volume Portainer runtime.

### 3. Planification cron

Fichier:

- `/etc/cron.d/portainer-backup-nas`

Regles:

- tous les jours a 02:50: export local vers NAS;
- tous les dimanches a 03:00: restore smoke test.

### 4. Validation realisee

- export NAS execute avec succes;
- checksum verifiee OK;
- test de restauration simple execute OK;
- archives visibles dans le dossier backup NAS.

### 5. Controle hebdo en 10 secondes

Commande unique:

```bash
sudo /usr/local/sbin/portainer_weekly_healthcheck.sh
```

Alias pratique (utilisateur `sebastien`):

```bash
pcheck
```

Ce controle affiche:

- statut des conteneurs `portainer` et `netdata`;
- code HTTP local de Portainer (attendu: `HTTP_CODE=200` ou `HTTP_CODE=307` selon redirection);
- presence du dernier backup NAS + verification checksum;
- extrait du log de restore smoke test.

Interpretation rapide:

- si `HTTP_CODE` differe de `200` et `307`: verifier `sudo docker compose ps` puis `sudo docker logs portainer --tail 100`;
- si backup NAS absent: lancer `sudo /usr/local/sbin/portainer_backup_to_nas.sh`;
- si checksum KO: regenerer un backup local puis relancer l'export NAS.

### 6. Diagnostic express depuis Windows (commande unique)

Commande PowerShell (poste admin Windows):

```powershell
$ip='192.168.8.189'; 22,9443,19999 | ForEach-Object { $p=$_; $r=Test-NetConnection -ComputerName $ip -Port $p -WarningAction SilentlyContinue; [PSCustomObject]@{Host=$ip;Port=$p;Open=$r.TcpTestSucceeded} } | Format-Table -AutoSize; curl.exe -k -I https://$ip`:9443 | Select-Object -First 1
```

Lecture rapide:

- `Open=True` sur `22`: acces SSH OK;
- `Open=True` sur `9443`: Portainer joignable;
- `Open=True` sur `19999`: Netdata joignable;
- `HTTP/1.1 200` ou `HTTP/1.1 307`: reponse HTTPS Portainer conforme.

## Verdict Actuel

Au vu des verifications deja observees:

- Portainer demarre correctement;
- Portainer repond bien en HTTPS sur `9443`;
- l'installation est exploitable;
- le point a surveiller est surtout l'initialisation admin et le durcissement progressif.

## Post-Mortem: Incident daemon.json

### Symptome observes

- les conteneurs existaient dans `/var/lib/docker/containers`;
- `docker ps -a` ne montrait plus les conteneurs;
- Portainer ne repondait plus sur `9443`;
- `docker info` montrait `Docker Root Dir: /var/lib/docker/100000.100000`.

### Cause racine

L'option `userns-remap` a ete activee apres coup dans `/etc/docker/daemon.json`.

Effet:

- Docker a bascule vers un root dir namespace (`/var/lib/docker/100000.100000`);
- les conteneurs historiques n'etaient plus visibles dans la vue active du daemon.

### Remediation appliquee

Configuration finale retenue:

```json
{
	"live-restore": true
}
```

Resultat:

- retour de `Docker Root Dir: /var/lib/docker`;
- retour des conteneurs dans `docker ps -a`;
- Portainer relance et accessible en HTTPS.

## Garde-Fous Avant Modification De daemon.json

### 1. Sauvegarder avant chaque changement

```bash
sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak.$(date +%F-%H%M%S)
```

### 2. Verifier la config active avant changement

```bash
sudo docker info | egrep 'Docker Root Dir|Live Restore Enabled|userns|Userns|Storage Driver'
```

### 3. Valider JSON avant restart

```bash
sudo python3 -m json.tool /etc/docker/daemon.json >/dev/null && echo JSON_OK
sudo sed -i '1s/^\xEF\xBB\xBF//' /etc/docker/daemon.json
```

### 4. Redemarrer et verifier immediatement

```bash
sudo systemctl restart docker
sudo docker ps -a
curl -k -I https://localhost:9443
```

### 5. Interdits en production stable

- ne pas activer `userns-remap` sur une instance deja en service sans plan de migration explicite;
- ne pas melanger des changements daemon + stack applicative dans la meme intervention;
- ne jamais lancer `docker system prune` durant une phase de recovery.

### 6. Template minimal recommande

```json
{
	"live-restore": true
}
```

## Audit Technique Docker + Portainer (2026-06-20)

### Perimetre

- etat service Docker (systemd, daemon, runtime);
- etat Portainer (conteneur, compose, HTTPS, logs);
- exposition reseau (ports publies, pare-feu);
- persistance (volumes, empreinte stockage).

### Constat principal

- Docker actif, active au demarrage, runtime stable;
- daemon conforme: `live-restore=true`, root dir revenu a `/var/lib/docker`;
- Portainer operationnel en `2.39.3`, HTTPS `200 OK` sur `9443`;
- Netdata operationnel et `healthy`;
- API Docker TCP (`2375/2376`) non exposee.

### Risques identifies

- pare-feu inactif initialement (surface reseau trop large), corrige pendant l'audit;
- certificat et chiffrement absents au depart, corriges en Niveau 2;
- risque residuel: certificat auto-signe interne (identite propre mais non signe par une AC de confiance).

### Hardening applique pendant l'audit

Regles UFW appliquees:

- politique par defaut: `deny incoming`, `allow outgoing`;
- autorisation SSH: `OpenSSH`;
- autorisation Portainer: `9443/tcp` depuis `192.168.8.0/24`;
- autorisation Netdata: `19999/tcp` depuis `192.168.8.0/24`.

Etat final UFW:

- actif au runtime;
- journalisation active (niveau low);
- regles numerotees presentes et coherentes avec le besoin LAN.

### Verifications post-hardening

- `docker ps` OK: `portainer` et `netdata` en `Up`;
- test local Portainer: `curl -k -I https://localhost:9443` => `HTTP/1.1 200 OK`;
- test local Netdata: reponse HTTP recue (service joignable).

### Reste a faire (priorite basse)

- remplacer le certificat auto-signe par un certificat emis par une AC interne ou publique (confort navigateur et confiance PKI);
- ajouter une revue trimestrielle du journal `/var/log/portainer-restore-smoke.log` dans la routine admin.

## Historique Des Versions

- `2026-06-20` - `v1.6` - ajout commande PowerShell de diagnostic express Windows (ports 22/9443/19999 + entete HTTPS Portainer).
- `2026-06-20` - `v1.5` - ajout alias `pcheck` et clarification du code HTTP attendu (200/307) pour le controle hebdo.
- `2026-06-20` - `v1.4` - ajout niveau 3 allege applique (export NAS, checksum, restore smoke test, cron dedie).
- `2026-06-20` - `v1.3` - application du durcissement niveau 2 (secret de chiffrement, TLS personnalise, sauvegarde cron avec retention).
- `2026-06-20` - `v1.2` - ajout audit Docker+Portainer et hardening UFW applique (SSH + LAN 9443/19999).
- `2026-06-20` - `v1.1` - ajout post-mortem de l'incident daemon.json et garde-fous de prevention.
- `2026-06-20` - `v1.0` - creation du runbook admin Portainer separe du guide d'installation.
