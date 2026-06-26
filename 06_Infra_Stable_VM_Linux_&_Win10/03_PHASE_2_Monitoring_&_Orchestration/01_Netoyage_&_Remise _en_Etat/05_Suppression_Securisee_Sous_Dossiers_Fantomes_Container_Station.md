# Suppression securisee des sous-dossiers fantomes Container Station - SebInfraNAS

Date de reference: 2026-06-26
Contexte: NAS SebInfraNAS (QNAP TS-264)

## Objectif

Documenter l intervention de suppression des sous-dossiers fantomes crees par doublon de chemin apres reinstallation de Container Station, sans impact sur le dossier Docker actif.

## 1. Confirmation d arret de Container Station et Docker

Verification effectuee:
- Container Station arrete avant operation de suppression.
- Docker inactif pendant l intervention.
- Le compte admin utilise sur le NAS est equivalent a root pour cette operation de maintenance.

Commande de controle utilisee:

```bash
ps aux | grep -E "dockerd|containerd" | grep -v grep
```

Resultat attendu:
- Aucun process dockerd/containerd actif.

## 2. Identification du dossier actif et du dossier fantome

Methode:
- Le dossier actif est celui pointe par Docker Root Dir.
- Le dossier fantome est la branche residuelle non pointee, issue de l ancienne installation.

Commande de reference:

```bash
/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker info | grep "Docker Root Dir"
```

Analyse:
- Dossier actif: branche retournee par Docker Root Dir.
- Dossier fantome: branche en doublon de type container-station-data/container-station-data non utilisee par le runtime courant.

## 3. Liste des sous-dossiers supprimes

Perimetre de suppression:
- Sous-dossiers fantomes uniquement, dans la branche non active.
- Aucun dossier du Docker Root Dir actif n a ete supprime.

Trace de suppression executee:
- /share/CACHEDEV1_DATA/Container/container-station-data/application
- /share/CACHEDEV1_DATA/Container/container-station-data/image
- /share/CACHEDEV1_DATA/Container/container-station-data/lib
- /share/CACHEDEV1_DATA/Container/container-station-data/tmp

Validation d execution:
- Les commandes `rm -rf` ont ete executees sans erreur.
- Le dossier actif a ete conserve: `container-station-data/container-station-data`.

## 4. Justification de l intervention

Justification technique:
- Ces sous-dossiers correspondent a des restes de l ancienne installation.
- La reinstallation de Container Station a provoque une recreation partielle de structure, produisant un doublon visuel de chemin.
- Le nettoyage evite les confusions de diagnostic et facilite la maintenance future.

## 5. Redemarrage de Container Station

Action:
- Container Station redemarre apres suppression.
- Redemarrage confirme sans incident.

Objectif:
- Relancer le moteur Docker sur une base de dossiers nettoyee.

## 6. Verification post-redemarrage

### 6.1 Verification Docker Root Dir

```bash
/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker info | grep "Docker Root Dir"
```

Resultat attendu:
- Docker Root Dir coherent, stable, et pointe vers la branche active uniquement.

### 6.2 Verification des conteneurs

```bash
/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker ps -a
```

Resultat attendu:
- Conteneurs attendus presents et sans anomalie de redemarrage.

### 6.3 Verification des volumes

```bash
/share/CACHEDEV1_DATA/.qpkg/container-station/bin/docker volume ls
```

Resultat attendu:
- Volumes attendus visibles, sans reference aux sous-dossiers fantomes supprimes.

## Conclusion

- Arret de securite respecte avant suppression.
- Contexte de droits confirme: compte admin equivalent root sur NAS QNAP.
- Dossier actif preserve.
- Sous-dossiers fantomes traites en perimetre controle.
- Dossiers supprimes: application, image, lib, tmp.
- Redemarrage et controles post-operation valides.
- Nettoyage conforme pour stabiliser l environnement Docker NAS.

CLEANUP_CONTAINER_STATION_OK
