🟩 PLAN TECHNIQUE — Mise en place complète sous Windows 10
Ce plan est organisé en phases, comme un vrai projet d’infrastructure.

🟥 PHASE 1 — Préparation de l’environnement Windows 10

1. Installer les composants nécessaires:

. Docker Desktop Windows
. WSL2 + Ubuntu (obligatoire pour Docker Linux containers)
. VSCode Windows
. Extensions : Docker, Remote WSL, Dev Containers
. Claude Desktop Windows (pour MCP)
. Guided link : Préparer Win10

1.2. Vérifier que Docker utilise WSL2

. Docker Desktop → Settings → General → “Use WSL2 backend”
. Vérifier que la distro Ubuntu est activée dans “Resources → WSL Integration”

1.3. Monter le dossier partagé NAS sous Windows

. Tu dois retrouver exactement le même chemin logique que sous Linux.

🟦 PHASE 2 — Reproduire le projet MCP sous Windows

1. Cloner / copier ton dossier mcp-netdata
Depuis le NAS ou Git (si tu veux versionner plus tard).

Chemin cible Windows :
C:\Users\Sébastien\Documents\mcp-netdata
ou
\\NAS\infradata\07_VSCode_Workspaces\...

1.2. Ouvrir le projet dans VSCode Windows
VSCode → “Open Folder” → ton dossier MCP.

1.3. Vérifier Docker Compose
Dans un terminal VSCode Windows :

docker compose up -d

Tu dois obtenir le même conteneur MCP, avec :

. Node 20
. AppArmor (non applicable sous Win10)
. Healthcheck
. MCP tools
. STDIO pour Claude

🟩 PHASE 3 — Reproduire le monitoring Netdata sous Windows
⚠️ Important : Netdata ne tourne pas nativement sous Windows.
Mais tu as 3 options :

Option A — Monitoring via WSL2 (recommandé)
Tu installes Netdata dans Ubuntu WSL2, ce qui te donne :

. Monitoring du kernel Linux WSL2
. Monitoring Docker (via WSL2)
. Monitoring du conteneur MCP
. Dashboard identique à Linux Mint
. Connexion possible à Netdata Cloud

Option B — Monitoring via Netdata Cloud
Tu relies :

- ton Linux Mint
- ton Win10 (via WSL2)
- ton NAS
- tes futures VMs

…dans un seul dashboard Cloud.

Option C — Monitoring via VM Linux sur Win10
Tu installes une VM Linux (Mint ou Ubuntu) dans VirtualBox/Hyper-V, et tu y mets Netdata.

🟥 PHASE 4 — Reproduire la logique de sécurité
Sous Windows, AppArmor n’existe pas.
Donc on remplace par :

. Isolation Docker Windows
. User non-root dans le conteneur (déjà fait)
. Healthcheck strict
. Pas de ports exposés
. Pas de volumes sensibles
. Pas de privilèges élevés

🟦 PHASE 5 — Reproduire la connexion Claude ↔ MCP
Dans Claude Desktop Windows :

. Paramètres → Développeur → MCP
. Ajouter un serveur MCP local
. Pointer vers ton conteneur MCP Windows

Tester avec :

/mcp servers
/mcp call docker-mcp get-health

🟩 PHASE 6 — Vérification de cohérence Linux ↔ Win10
On doit vérifier que :

. Le conteneur MCP Windows répond exactement comme celui de Linux
. Les outils MCP sont identiques
. Le comportement STDIO est identique
. Le healthcheck est identique
. Le monitoring Netdata voit bien le conteneur
. Les chemins NAS sont cohérents
. Les scripts (setup_mcp.sh, setup_mcp_v2.sh) fonctionnent via WSL2

🟥 PHASE 7 — Intégration dans ton projet global SebInfra 2026
Tu veux un environnement :

. Linux Mint (PC)
. Windows 10 (PC)
. NAS QNAP
. VM Linux
. VM Windows
. Docker
. Netdata
. MCP
. Monitoring unifié
. Communication croisée Linux ↔ Win10 ↔ NAS ↔ VMs
. Donc sous Win10, on prépare aussi :
. Accès NAS 2.5GbE
. Accès aux VMs
. Monitoring centralisé
. Scripts de démarrage/arrêt propres
. Documentation VSCode

🟦 PHASE 8 — Ce à quoi s’attendre
✔ Ce qui sera identique à Linux

. Le conteneur MCP
. Le comportement Node
. Les outils MCP
. Le healthcheck
. La communication Claude ↔ MCP
. Le monitoring Docker
. Le monitoring MCP
. Le dossier projet
. La logique de sécurité interne au conteneur

✔ Ce qui sera différent

. Pas d’AppArmor
. Netdata tourne dans WSL2 (ou Cloud)
. Docker utilise WSL2 comme backend
. Les chemins Windows sont différents
. Les permissions sont gérées par Windows, pas Linux

✔ Ce qui sera amélioré

. Monitoring multi-nœuds via Cloud
. Cohérence Linux ↔ Win10
. Documentation centralisée
. Architecture hybride complète
