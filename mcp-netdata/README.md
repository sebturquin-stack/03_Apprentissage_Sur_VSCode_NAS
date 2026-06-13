# Netdata MCP

Serveur MCP Node.js pour interroger un agent Netdata local via HTTP et exposer des outils utilisables depuis un client MCP.

## Description du projet

Ce projet fournit un connecteur MCP en transport stdio.
Il expose des outils de lecture de snapshots de metriques Netdata:

- get_netdata_info
- get_cpu_snapshot
- get_ram_snapshot
- get_disk_snapshot

Objectif principal:

- Offrir une passerelle simple entre un client MCP et les endpoints Netdata.
- Garder une execution stable en conteneur Docker avec un healthcheck explicite.

## Structure du dossier

- Dockerfile: image multistage Node 20 optimisee pour la production.
- docker-compose.yml: orchestration locale avec limites, logs et healthcheck.
- netdata-mcp.js: serveur MCP et logique d'appel Netdata.
- package.json: metadonnees projet et scripts npm.
- package-lock.json: verrouillage des versions npm.
- .env.example: modele de variables d'environnement pour Docker Compose.
- .dockerignore: reduction du contexte de build Docker.
- setup_mcp.sh, setup_mcp_v2.sh, start-netdata-mcp.sh: scripts d'aide.

## Installation

Prerequis:

- Node.js 20+
- npm 10+
- Docker Desktop ou Docker Engine + Compose v2
- Docker Compose (Netdata est orchestre dans la stack)

Installation locale:

1. Ouvrir un terminal dans le dossier mcp-netdata.
2. Installer les dependances:
   npm install
3. Lancer le serveur:
   npm start

Configuration Docker Compose:

1. Copier le fichier d'exemple:
   cp .env.example .env
2. Ajuster les valeurs si necessaire (URL Netdata, timeout).

Variables d'environnement supportees:

- NETDATA_BASE_URL
  - Defaut (compose): <http://netdata:19999>
  - Exemple externe: <http://localhost:19999>
- NETDATA_TIMEOUT_MS
  - Defaut: 5000

## Docker build / run

Build image:

- docker compose build

Demarrage:

- docker compose up -d

Services demarres:

- netdata (UI + API): <http://localhost:19999>
- netdata-mcp (service MCP)

Persistance Netdata:

- Le service Netdata utilise un volume nomme `netdata_data` monte sur `/var/lib/netdata`.
- Ce volume conserve les metriques, journaux et alertes Netdata entre redemarrages.
- Le mode volume nomme Docker est compatible WSL2 + Docker Desktop.

Verification:

- docker ps
- docker compose logs -f netdata-mcp

Arret:

- docker compose down

Note: pour supprimer aussi les donnees persistantes Netdata, utiliser `docker compose down -v`.

Notes runtime:

- L'image utilise Node 20 slim.
- Le conteneur tourne en utilisateur non-root 1000:1000.
- Le healthcheck execute node /app/netdata-mcp.js --healthcheck.

## Scripts npm

Scripts declares dans package.json:

- npm start
  - Lance le serveur MCP.
- npm run dev
  - Lance le serveur en mode watch.
- npm test
  - Lance les tests Node natifs.
- npm run smoke
  - Verifie l etat de la stack et la communication MCP -> Netdata.
- npm run status
  - Affiche un statut clair MCP/Netdata et retourne 0 (OK) ou 1 (FAIL).
- npm run restart
  - Redemarre la stack compose et verifie les checks de base.
- npm run backup
  - Sauvegarde le volume de donnees Netdata sans arreter la stack.
- npm run format
  - Formate les fichiers via Prettier.
- npm run lint
  - Lance ESLint sur le projet.

## Dashboard Netdata custom

Acceder a Netdata:

- Ouvrir l URL: <http://localhost:19999>
- Verifier que le service `netdata` est actif: `docker compose ps`

Ajouter un dashboard custom:

- Creer un dossier local dedie, par exemple `./netdata-custom/`.
- Ajouter tes definitions de dashboard et assets dans ce dossier.
- Monter ce dossier dans le conteneur Netdata via un bind mount compose.

Ou placer les fichiers `custom.d`:

- Cote projet: `./netdata-custom/custom.d/`
- Cote conteneur: `/etc/netdata/custom.d/`

Exemple de bind mount a ajouter au service `netdata`:

- `./netdata-custom/custom.d:/etc/netdata/custom.d:ro`

Apres ajout/modification:

- Redemarrer Netdata: `docker compose restart netdata`
- Recharger le dashboard dans le navigateur (Ctrl+F5)

## Integration Netdata

L'integration est geree par Docker Compose avec un reseau commun `mcp-net`.

Communication MCP -> Netdata:

- URL interne utilisee par defaut: `http://netdata:19999`
- Variable transmise au service MCP: `NETDATA_BASE_URL`
- Timeout HTTP MCP vers Netdata: `NETDATA_TIMEOUT_MS`
- Le service MCP attend que Netdata soit healthy via `depends_on`.

Le serveur interroge Netdata via:

- /api/v1/info pour les informations globales
- /api/v1/data pour les snapshots CPU, RAM et disque

Comportement des appels:

- Timeouts geres avec AbortController
- Gestion des erreurs HTTP et reseau
- Reponse MCP standardisee en payload texte JSON

Charts utilises par defaut:

- CPU: system.cpu
- RAM: system.ram
- Disque: system.io

## Notes de securite

Mesures en place:

- Execution en utilisateur non-root
- Profil AppArmor dans la compose
- Limites CPU et memoire
- Rotation de logs json-file
- Healthcheck actif
- Dependances lockees via package-lock.json

Bonnes pratiques recommandees:

- Restreindre NETDATA_BASE_URL a une cible de confiance
- Eviter d'exposer inutilement le service sur le reseau
- Mettre a jour regulierement les dependances npm
- Verifier periodiquement les logs et l'etat de sante du conteneur
