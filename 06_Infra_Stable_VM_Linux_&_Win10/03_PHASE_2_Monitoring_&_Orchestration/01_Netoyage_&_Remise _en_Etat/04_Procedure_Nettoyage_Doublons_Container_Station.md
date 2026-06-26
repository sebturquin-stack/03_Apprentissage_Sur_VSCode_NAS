# Procedure de nettoyage des dossiers doublons Container Station sur SebInfraNAS

Date de reference: 2026-06-26
Contexte: NAS SebInfraNAS (QNAP TS-264)

## Objectif

Supprimer proprement les sous-dossiers fantomes recrees apres reinstallation de Container Station, tout en preservant le dossier Docker actif et la stabilite des conteneurs/volumes.

## 1. Analyse des deux dossiers container-station-data

Constat observe:
- Presence d une arborescence avec doublon de type container-station-data/container-station-data.
- Ce motif indique souvent un ancien chemin conserve puis recree par la couche de gestion QNAP lors de la reinstallation.

Verification de base (lecture seule):

```bash
ls -lah /share/CACHEDEV1_DATA/Container/container-station-data
ls -lah /share/CACHEDEV1_DATA/Container/container-station-data/container-station-data
```

## 2. Identification du dossier actif et du dossier fantome

Regle de decision:
- Le dossier actif est celui pointe par Docker Root Dir.
- Le dossier fantome est celui non pointe par Docker Root Dir et ne contenant pas les donnees runtime actuelles.

Commande de reference (QNAP Docker):

```bash
/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker info | grep "Docker Root Dir"
```

Verification complementaire:

```bash
/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker ps -a
/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker volume ls
```

Interpretation attendue:
- Si Docker Root Dir pointe la branche A, alors la branche B est candidate fantome.
- Ne jamais supprimer le chemin retourne par Docker Root Dir.

## 3. Cause du doublon

Cause retenue:
- Reinstallation de Container Station.
- Recreation automatique de dossiers de travail/metadata.
- Conservation possible d un ancien niveau de dossier, d ou le doublon visuel container-station-data/container-station-data.

## 4. Procedure securisee

Important:
- L intervention se fait hors charge critique.
- Effectuer une sauvegarde des donnees critiques avant suppression.

### Etape 1 - Arret de Container Station

Arreter Container Station depuis l interface QNAP (App Center) ou via le mecanisme d administration du NAS.

### Etape 2 - Verification de l arret de Docker

```bash
ps aux | grep -E "dockerd|containerd" | grep -v grep
```

Resultat attendu:
- Aucun process dockerd/containerd actif.

### Etape 3 - Suppression des sous-dossiers fantomes

Exemple de suppression ciblee (adapter le chemin fantome identifie):

```bash
rm -rf /share/CACHEDEV1_DATA/Container/container-station-data/container-station-data/<sous-dossier_fantome>
```

Option de controle avant suppression:

```bash
du -sh /share/CACHEDEV1_DATA/Container/container-station-data/*
```

Regles de securite:
- Supprimer uniquement les sous-dossiers confirmes fantomes.
- Ne jamais supprimer le dossier racine actif de Docker Root Dir.
- Proceder par lots et verifier apres chaque suppression.

### Etape 4 - Redemarrage de Container Station

Relancer Container Station depuis App Center, puis attendre la reprise complete.

### Etape 5 - Verification du Docker Root Dir

```bash
/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker info | grep "Docker Root Dir"
```

Resultat attendu:
- Docker Root Dir coherent et stable.

### Etape 6 - Verification des conteneurs et volumes

```bash
/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker ps -a
/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker volume ls
```

Resultat attendu:
- Les conteneurs attendus sont presents et stables.
- Les volumes attendus sont presents, sans reference aux sous-dossiers fantomes supprimes.

## Controle final de stabilite

Checklist:
- Docker Root Dir valide.
- Conteurs critiques operationnels.
- Volumes critiques visibles.
- Aucun impact fonctionnel sur netdata-nas.

Conclusion:
- Nettoyage des doublons effectue de facon securisee.
- Infrastructure Docker NAS preservee.

CLEANUP_CONTAINER_STATION_OK
