# AGENTS.md

## Objectif

Ce workspace est orienté documentation, avec un seul serveur MCP exécutable dans [mcp-netdata](./mcp-netdata/).
Comportement par défaut attendu des agents de code: préserver la structure Markdown, éviter les réécritures larges et privilégier des changements incrémentaux et vérifiables.

## Carte Du Projet

- Hub documentaire: fichiers Markdown à la racine et guides de dossiers.
- Implémentation MCP: [mcp-netdata/netdata-mcp.js](./mcp-netdata/netdata-mcp.js)
- Métadonnées du package MCP: [mcp-netdata/package.json](./mcp-netdata/package.json)
- Déclaration MCP pour VS Code: [.vscode/mcp.json](./.vscode/mcp.json)
- Préférences du workspace: [.vscode/settings.json](./.vscode/settings.json)

## Exécuter Et Vérifier

Depuis [mcp-netdata](./mcp-netdata/):

- Installer les dépendances: `npm install`
- Démarrer le serveur: `npm start`
- Démarrage alternatif: `node netdata-mcp.js`

Notes:

- Aucun script de test formel n'existe pour le moment.
- Le serveur utilise un transport stdio; aucun listener HTTP n'est attendu par défaut.

## Notes D'Architecture (mcp-netdata)

- Runtime: Node.js ESM (`"type": "module"`).
- Transport: `StdioServerTransport` via MCP SDK.
- Outils exposés: `get_netdata_info`, `get_cpu_snapshot`, `get_ram_snapshot`, `get_disk_snapshot`.
- La validation des paramètres utilise `zod`.
- Variables d'environnement:
  - `NETDATA_BASE_URL` (valeur par défaut `http://localhost:19999`)
  - `NETDATA_TIMEOUT_MS` (valeur par défaut `5000`)

## Conventions D'Édition

- Garder la documentation en français sauf si un fichier est explicitement en anglais.
- Préserver les conventions de nommage et la taxonomie des dossiers existantes.
- Pour la documentation, privilégier des modifications ciblées plutôt que des réécritures complètes.
- Pour le code MCP, conserver les réponses encapsulées dans un payload texte MCP `content`.

## Pièges Connus

- Exécuter `node /app/netdata-mcp.js` dans un REPL Node échoue; cette commande doit être lancée dans un shell.
- Si `NETDATA_BASE_URL` change, redémarrer le processus/conteneur.
- Les détails de déploiement du conteneur sont documentés ici:
  - [Configuration finale du conteneur Node 20](./05_Reprise_Projet_NetData/02_Config%20du%20Container/01_Configuration_finale_Node20_MCP_Netdata.md)

## Documentation Liée (Ne Pas Dupliquer)

- Vue d'ensemble du workspace: [02_REDME-Atelier I Général - SébCore.md](./02_REDME-Atelier%20I%20Général%20-%20SébCore.md)
- README de la bibliothèque de templates: [01_VSCode_Environnement/01_Templates_Documents/README.md](./01_VSCode_Environnement/01_Templates_Documents/README.md)
- Parcours projet Netdata: [05_Reprise_Projet_NetData](./05_Reprise_Projet_NetData/)

## Règles De Travail Agent

- Avant d'éditer, lire le guide Markdown le plus proche et pertinent dans la zone ciblée.
- En cas de demande de revue, prioriser d'abord les bugs, régressions, risques et tests manquants.
- Ne pas introduire de nouvelles hypothèses d'infrastructure (ports, services, chemins OS) sans confirmation dans la documentation existante.
- Préférer les liens vers la documentation existante plutôt que la copie de procédures longues.
