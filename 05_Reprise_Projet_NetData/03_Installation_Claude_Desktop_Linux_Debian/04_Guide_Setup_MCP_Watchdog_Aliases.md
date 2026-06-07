# Guide complet - Setup MCP Netdata, watchdog systemd et aliases bash

## Objectif

Ce guide donne une vue claire et durable de la configuration locale MCP Netdata:

- watchdog systemd (service + timer)
- aliases bash de pilotage rapide
- commandes de verification
- depannage en cas d'ecart

## Fichiers et composants

- Script principal recommande: `mcp-netdata/setup_mcp_v2.sh`
- Script historique (peut etre degrade selon environnement SMB): `mcp-netdata/setup_mcp.sh`
- Service systemd: `mcp-netdata-watchdog.service`
- Timer systemd: `mcp-netdata-watchdog.timer`
- Script watchdog installe: `/usr/local/bin/mcp-netdata-watchdog.sh`
- Bloc aliases ecrit dans: `~/.bashrc`

## Ce que fait le setup

1. Ecrit le script watchdog local dans `/usr/local/bin`.
2. Installe/met a jour l'unite service systemd.
3. Installe/met a jour l'unite timer systemd.
4. Recharge systemd et active le timer.
5. Reecrit un bloc aliases idempotent dans `~/.bashrc`.

## Aliases/fonctions installes

Fonctions:

- `mcp_netdata_status`
- `mcp_netdata_logs`

Aliases:

- `mcp-start`: demarre le conteneur MCP puis lance le service watchdog.
- `mcp-stop`: arrete le conteneur MCP puis stoppe le service watchdog.
- `mcp-restart`: restart conteneur MCP puis relance le service watchdog.
- `mcp-status`: appelle `mcp_netdata_status`.
- `mcp-logs`: affiche les 200 dernieres lignes de logs watchdog.
- `mcp-logsf`: suit les logs watchdog en temps reel.

## Procedure recommandee (pas a pas)

### 1) Lancer le setup

```bash
cd '/run/user/1000/gvfs/smb-share:server=sebinfranas.local,share=infradata/07_VSCode_Workspaces/03_Apprentissage_Sur_VSCode/mcp-netdata'
bash setup_mcp_v2.sh
```

### 2) Recharger le shell interactif

```bash
source ~/.bashrc
```

### 3) Verifier systemd

```bash
sudo systemctl status mcp-netdata-watchdog.service --no-pager
sudo systemctl status mcp-netdata-watchdog.timer --no-pager
```

Etat attendu:

- service `oneshot` souvent en `inactive (dead)` entre 2 executions: normal
- timer en `active (waiting)`: attendu

### 4) Verifier les aliases dans un shell interactif

```bash
type mcp-start mcp-stop mcp-restart mcp-status mcp-logs mcp-logsf
```

### 5) Tests fonctionnels

```bash
mcp-start
mcp-status
mcp-logs
# sortie avec Ctrl+C
mcp-logsf
mcp-stop
```

## Idempotence: comportement attendu

Le bloc dans `~/.bashrc` est encadre par:

- `# >>> mcp-netdata aliases >>>`
- `# <<< mcp-netdata aliases <<<`

A chaque relance du setup:

1. ancien bloc retire proprement
2. nouveau bloc reecrit une seule fois

## Verification rapide du bloc bashrc

```bash
sed -n '/# >>> mcp-netdata aliases >>>/,/# <<< mcp-netdata aliases <<</p' ~/.bashrc
```

## Depannage

### A) Les aliases semblent absents

Cause frequente: verification effectuee dans un shell non interactif.

Solution:

```bash
bash -ic "type mcp-start mcp-stop mcp-status mcp-logs mcp-logsf"
```

### B) Timer actif mais service inactif

Normal avec un service `Type=oneshot` declenche periodiquement par le timer.

### C) Le conteneur n'existe pas sous `01_Node-20_MCP`

Relancer le setup avec un nom explicite:

```bash
CONTAINER_NAME='NOM_REEL_CONTENEUR' bash setup_mcp_v2.sh
source ~/.bashrc
```

### C2) Erreur `network_error` / `fetch failed` sur `http://localhost:19999`

Symptome:

- l'outil `get_netdata_info` retourne `ok: false` avec `type: network_error`.

Cause:

- `localhost` est resolu depuis le conteneur MCP, pas depuis l'hote.

Correctif valide sur cet environnement:

- injecter `NETDATA_BASE_URL=http://172.17.0.1:19999` dans la commande MCP Claude Desktop.

Fichier:

- `~/.config/Claude/claude_desktop_config.json`

Extrait attendu:

```json
"mcpServers": {
	"netdata-mcp": {
		"command": "docker",
		"args": [
			"exec",
			"-i",
			"-e",
			"NETDATA_BASE_URL=http://172.17.0.1:19999",
			"01_Node-20_MCP",
			"node",
			"/app/netdata-mcp.js"
		]
	}
}
```

Puis:

1. redemarrer completement Claude Desktop
2. refaire un test `get_netdata_info`

Important:

- un simple refresh de fenetre n'est pas suffisant; il faut fermer puis relancer l'application pour recharger `claude_desktop_config.json`.

### D) Logs watchdog

```bash
mcp-logs
mcp-logsf
```

ou

```bash
sudo journalctl -u mcp-netdata-watchdog.service -u mcp-netdata-watchdog.timer --no-pager -n 200
```

## Notes d'exploitation

- Le setup demande sudo (ecriture systemd + /usr/local/bin).
- En environnement SMB/GVFS, preferer de petites modifications incrementales.
- En cas de doute, utiliser `setup_mcp_v2.sh` comme source de verite.

## Check-list finale

1. `setup_mcp_v2.sh` execute sans erreur bloquante.
2. timer `mcp-netdata-watchdog.timer` actif.
3. bloc aliases present une seule fois dans `~/.bashrc`.
4. `mcp-status` fonctionne en shell interactif.
5. `mcp-logs` et `mcp-logsf` affichent les journaux.

## Validation Claude Desktop (connexion MCP + appel outil)

### Prerequis verifies

- Le conteneur `01_Node-20_MCP` est en etat `Up`.
- Le timer `mcp-netdata-watchdog.timer` est `active (waiting)`.
- La config Claude contient bien:

- `~/.config/Claude/claude_desktop_config.json`
- section `mcpServers.netdata-mcp`
- commande `docker exec -i 01_Node-20_MCP node /app/netdata-mcp.js`

### Etape 1 - Verification connexion MCP dans Claude Desktop

1. Ouvrir Claude Desktop.
2. Ouvrir une nouvelle conversation.
3. Verifier que le serveur `netdata-mcp` est visible/actif dans les integrations MCP.

Verification technique possible cote logs:

```bash
grep -Rin "MCP Server connection requested for: netdata-mcp\|Launching MCP Server: netdata-mcp" ~/.config/Claude/logs/main.log | tail -n 10
```

Resultat attendu:

- traces de demande de connexion et lancement du serveur `netdata-mcp`.

### Etape 2 - Appel reel d'un outil Netdata

Dans Claude Desktop, envoyer un prompt explicite (exemple):

- `Peux-tu appeler l'outil get_netdata_info et me renvoyer le JSON brut ?`

Puis faire un 2eme test:

- `Appelle get_cpu_snapshot et resume le resultat en 3 lignes.`

Resultat attendu:

- reponse outil avec payload JSON (`ok: true` en nominal).
- si `ok: false`, message d'erreur explicite (timeout/network/http_error).

Verification logs de l'appel outil:

```bash
grep -Rin "tools/call\|get_netdata_info\|get_cpu_snapshot" ~/.config/Claude/logs/mcp-server-netdata-mcp.log | tail -n 20
```

### Validation obtenue (session du 2026-06-06)

Statut: `GO` (chaine MCP operationnelle)

Resultats observes:

- `get_netdata_info`: retour JSON valide de Netdata (`version: v1.43.2`, hote miroir detecte, alarmes remontees)
- `get_cpu_snapshot`: appel reussi, synthese CPU coherente (~50% de charge totale au moment du test)

Conclusion:

- la connexion Claude Desktop -> MCP Netdata est fonctionnelle
- les outils Netdata sont bien exploitables en conversation

## Plan de depannage immediat (si blocage)

### Cas A - Le serveur MCP n'apparait pas dans Claude Desktop

1. Verifier la config JSON:

```bash
sed -n '1,220p' ~/.config/Claude/claude_desktop_config.json
```

1. Redemarrer Claude Desktop completement.
2. Recontroler les logs `main.log` avec la commande ci-dessus.

### Cas B - Connexion MCP ok mais aucun outil disponible

1. Verifier le log serveur MCP:

```bash
tail -n 80 ~/.config/Claude/logs/mcp-server-netdata-mcp.log
```

1. Confirmer la presence de `tools/list` et des outils `get_netdata_info`, `get_cpu_snapshot`, `get_ram_snapshot`, `get_disk_snapshot`.

### Cas C - Outil appele mais erreur runtime

1. Tester l'etat conteneur:

```bash
docker ps --filter 'name=01_Node-20_MCP'
```

1. Tester watchdog:

```bash
sudo systemctl status mcp-netdata-watchdog.timer --no-pager
sudo systemctl status mcp-netdata-watchdog.service --no-pager
```

1. Relancer proprement:

```bash
mcp-restart
mcp-status
```

### Cas D - Aliases absents dans un terminal

Cause frequente: shell non interactif.

Solution:

```bash
bash -ic "type mcp-start mcp-stop mcp-restart mcp-status mcp-logs mcp-logsf"
```
