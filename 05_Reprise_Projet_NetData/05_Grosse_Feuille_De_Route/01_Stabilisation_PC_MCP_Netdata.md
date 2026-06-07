🟩 Stabilisation PC MCP Netdata — la feuille de route officielle
(avec images pour visualiser chaque couche)

🟦 1. Vérifier la stabilité du montage CIFS
Le montage CIFS est la base absolue : si /mnt/infradata tombe, tout tombe.

Objectifs
Montage automatique au boot

Credentials propres

Pas de timeout

Pas de “Permission denied”

Pas de dépendance GVFS

/etc/fstab propre

Credentials corrects

Test manuel OK

Test reboot OK

Test Docker OK

Vérifier_fstab

Tester_montage

Durcir_CIFS

🟩 2. Stabiliser Docker + MCP
Ton conteneur MCP est le cœur du pipeline Claude ↔ VSCode ↔ Netdata.

Objectifs
Conteneur toujours up

Bind mount toujours valide

Logs propres

Redémarrage automatique

Healthcheck intégré

docker ps stable

/app visible dans le conteneur

MCP répond à get_netdata_info

MCP répond à get_cpu_snapshot

Ajouter un --restart=always

Ajouter un healthcheck Docker

Activer_restart_always

Ajouter_healthcheck

Vérifier_bind_mount

🟧 3. Stabiliser Netdata local
Netdata doit être propre, léger, sans bruit, sans fausses alertes.

Objectifs
dbengine optimisé

Retention adaptée

Alertes pertinentes

Pas de spam disque

Pas de CPU spikes

dbengine à 256–512 MB

Rotation des logs

Désactivation des collectors inutiles

Alertes CPU/RAM/IO calibrées

Dashboard local propre

Nettoyer_collectors

🟨 4. Stabiliser Claude Desktop + VSCode
Ton workflow doit être fluide, sans déconnexion, sans REPL Node, sans erreur MCP.

Objectifs
Claude toujours connecté

VSCode toujours sur /mnt/infradata

Pas de workspace GVFS

MCP visible dans la vue MCP

Logs propres

Checklist
Workspace VSCode = /mnt/infradata/...

MCP = “Running” dans la vue Claude

Pas de REPL Node

Pas de “Server disconnected”

Pas de “Cannot find module /app/...”

Vérifier_vue_MCP

Éviter_GVFS

Stabiliser_Claude

🟩 5. Ajouter un watchdog systemd
Le watchdog systemd est la ceinture de sécurité :
si Docker tombe, il relance.
Si CIFS tombe, il remonte.
Si MCP tombe, il redémarre.

Objectifs
Auto‑heal complet

Logs propres

Redémarrage automatique

Monitoring local

Créer_watchdog

Créer_watchdog_CIFS

Créer_watchdog_Docker

🟦 6. Ajouter les alias shell (qualité de vie)
Tu vas adorer ça.

Alias recommandés
mcp-start

mcp-stop

mcp-status

mcp-logs

mcp-logsf

mcp-restart

cifs-restart

docker-clean

🟩 7. Validation finale (PC stabilisé)
Quand ces 6 blocs sont verts, ton PC devient :

un nœud MCP fiable,

un serveur Netdata stable,

un client CIFS robuste,

un hôte Docker propre,

un point d’accès Claude/VSCode parfait,

la base de ton futur écosystème hybride.

Et à ce moment‑là, on pourra ajouter :

le NAS,

les VM Linux,

la VM Windows,

le streaming Netdata,

le dashboard combiné,

la communication totale Linux ↔ Windows ↔ NAS ↔ VM.

🟣 Sébastien, dis-moi ce que tu veux faire en premier
Voici les 3 portes possibles :

Sécuriser CIFS

Durcir Docker + MCP

Optimiser Netdata local

Tu choisis la première brique, et on la verrouille ensemble.
