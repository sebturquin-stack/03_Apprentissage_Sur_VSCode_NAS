# Checklist imprimable - MCP Netdata (30 secondes)

Date: ____ / ____ / ______

## 1) Controle express

- [ ] Conteneur actif

```bash
docker ps --filter 'name=01_Node-20_MCP'
```

- [ ] Timer watchdog actif

```bash
systemctl is-active mcp-netdata-watchdog.timer
```

- [ ] Alias charges (shell interactif)

```bash
bash -ic "type mcp-status mcp-logs mcp-restart"
```

## 2) Commandes quotidiennes

```bash
mcp-status
mcp-logs
mcp-restart
```

Suivi live:

```bash
mcp-logsf
```

## 3) Test Claude Desktop

Dans Claude Desktop:

- [ ] Prompt 1: Peux-tu appeler l'outil get_netdata_info et me renvoyer le JSON brut ?
- [ ] Prompt 2: Appelle get_cpu_snapshot et resume le resultat en 3 lignes.

## 4) Si erreur network_error (localhost:19999)

Verifier ce bloc dans ~/.config/Claude/claude_desktop_config.json:

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

- [ ] Fermer COMPLETEMENT Claude Desktop
- [ ] Relancer Claude Desktop
- [ ] Refaire les 2 prompts de test

## 5) Logs utiles

```bash
# watchdog
sudo journalctl -u mcp-netdata-watchdog.service -u mcp-netdata-watchdog.timer --no-pager -n 200

# MCP Claude
grep -Rin "tools/call|get_netdata_info|get_cpu_snapshot" ~/.config/Claude/logs/mcp-server-netdata-mcp.log | tail -n 20
```

## Verdict du jour

- [ ] GO
- [ ] NOK
- Note rapide: _________________________________________________
