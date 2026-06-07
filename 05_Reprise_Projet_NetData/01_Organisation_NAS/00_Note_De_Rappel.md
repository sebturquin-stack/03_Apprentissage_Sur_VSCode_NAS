# MCP dbhub en attente

## Etat actuel

Le serveur MCP `io.github.bytebase/dbhub` a ete retire de la configuration active du profil VS Code pour eviter l'erreur de demarrage automatique.

Les autres serveurs MCP restent utilisables:

- `io.github.ChromeDevTools/chrome-devtools-mcp`
- `local/netdata-mcp`

## Pourquoi il a ete desactive

Le mode demo de dbhub depend du driver SQLite natif `better-sqlite3`.

Dans l'environnement actuel, l'installation de ce driver echoue, ce qui provoque l'echec du demarrage automatique du serveur MCP.

## Ce qui ne doit pas etre modifie pendant la pause

- Ne pas toucher au serveur `local/netdata-mcp`.
- Ne pas supprimer le fichier `mcp.json` du profil utilisateur.
- Ne pas remettre dbhub en auto tant que la cause native SQLite n'est pas resolue.

## Bloc dbhub a remettre plus tard

```json
"io.github.bytebase/dbhub": {
  "type": "stdio",
  "command": "npx",
  "args": [
    "--yes",
    "--registry",
    "https://registry.npmjs.org",
    "--package",
    "better-sqlite3@11.9.0",
    "--package",
    "@bytebase/dbhub@0.21.2",
    "dbhub",
    "--transport",
    "stdio",
    "--demo"
  ],
  "env": {
    "DSN": "${input:DSN}",
    "DB_TYPE": "${input:DB_TYPE}",
    "DB_HOST": "${input:DB_HOST}",
    "DB_PORT": "${input:DB_PORT}",
    "DB_USER": "${input:DB_USER}",
    "DB_PASSWORD": "${input:DB_PASSWORD}",
    "DB_NAME": "${input:DB_NAME}",
    "TRANSPORT": "${input:TRANSPORT}",
    "PORT": "${input:PORT}",
    "ID": "${input:ID}",
    "SSH_HOST": "${input:SSH_HOST}",
    "SSH_PORT": "${input:SSH_PORT}",
    "SSH_USER": "${input:SSH_USER}",
    "SSH_PASSWORD": "${input:SSH_PASSWORD}",
    "SSH_KEY": "${input:SSH_KEY}",
    "SSH_PASSPHRASE": "${input:SSH_PASSPHRASE}"
  },
  "gallery": "https://api.mcp.github.com",
  "version": "0.21.2"
}
```

## Procedure de reprise

1. Verifier un environnement Node compatible avec `better-sqlite3`.
2. Reintegrer le bloc dbhub dans le `mcp.json` du profil VS Code.
3. Faire `Reload Window` dans VS Code.
4. Verifier si le serveur demarre sans erreur.
5. Si besoin, abandonner le mode demo et utiliser une vraie source DB avec DSN.

## Point de reprise conseille

Quand tu reviendras sur ce sujet, commencer par:

- tester `better-sqlite3` seul
- puis tester `dbhub` en manuel
- seulement ensuite remettre l'auto-demarrage
