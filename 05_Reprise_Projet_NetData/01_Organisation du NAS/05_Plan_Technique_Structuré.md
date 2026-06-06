🧩 PLAN TECHNIQUE DÉTAILLÉ – Relance du Projet MCP Linux ↔ Windows (SebInfraNAS)
Ce plan est organisé en 4 blocs techniques, chacun indispensable pour reconstruire un environnement propre, stable et évolutif.

1) 🟦 Structure du projet sur SebInfraNAS
Ton projet doit vivre dans :

\\SebInfraNAS\InfraData\07_VSCode_Workspaces\03_Apprentissage_Sur_VSCode\05_Reprise_Projet_MCP

📁 Structure recommandée

05_Reprise_Projet_MCP
│
├── 01_Documents
│     ├── README_Projet_MCP.md
│     ├── Architecture_MCP.pdf (plus tard)
│     └── Journal_de_Construction.md
│
├── 02_Serveur_MCP
│     ├── netdata-mcp.js
│     ├── package.json
│     ├── package-lock.json
│     └── config.json (si besoin)
│
├── 03_Tests_Communication
│     ├── test_windows.ps1
│     ├── test_linux.sh
│     └── test_mcp_requests.md
│
└── 04_Archives_Ancien_Projet
      └── (tout ce qui vient de l’ancien projet)

👉 Objectif :
Séparer proprement code, tests, docs, archives.

### 1.2) 🟩 Scripts nécessaires (Windows, Linux, MCP)

#### 🔹 Script Linux (NAS) – Lancement du serveur MCP

Ton NAS peut exécuter Node.js (via Container Station ou QNAP Node package).
Le script Linux doit :

- lancer ton serveur MCP
- écrire les logs
- rester actif en arrière-plan

Script : start_mcp.

```bash

cd /share/InfraData/07_VSCode_Workspaces/03_Apprentissage_Sur_VSCode/05_Reprise_Projet_MCP/02_Serveur_MCP
node netdata-mcp.js >> mcp.log 2>&1 &
echo "MCP Server started."

Script : stop_mcp.

# !/bin/bash

pkill -f netdata-mcp.js
echo "MCP Server stopped."

   🔹 Script Windows – Test de communication
Script : test_windows.ps1

Invoke-WebRequest -Uri "<http://seb-infra-nas:9000/status>" -UseBasicParsing

👉 Permet de vérifier que Windows ↔ NAS communiquent bien.

   🔹 Script MCP – Exemple de requête
Fichier : test_mcp_requests.md
Contient des requêtes types :
GET /metrics
GET /health
POST /query { "metric": "cpu" }

## 1.3) 🟧 Configuration MCP propre (mcp.json)

Ton fichier mcp.json doit maintenant pointer vers le serveur MCP hébergé sur SebInfraNAS, pas sur ton PC.

Exemple propre :

{
  "mcpServers": {
    "netdata": {
      "command": "node",
      "args": [
        "\\\\SebInfraNAS\\InfraData\\07_VSCode_Workspaces\\03_Apprentissage_Sur_VSCode\\05_Reprise_Projet_MCP\\02_Serveur_MCP\\netdata-mcp.js"
      ]
    }
  }
}

👉 Plus de boucle de démarrage, car :

- le serveur est stable
- il tourne sur le NAS
- ton PC ne fait que s’y

1.4) 🟪 Tests de communication Linux ↔ Windows ↔ VSCode
   🔹 Test 1 — Windows → NAS (HTTP)
Depuis PowerShell :

Invoke-WebRequest <http://seb-infra-nas:9000/status>

Résultat attendu :

200 OK

   🔹 Test 2 — VSCode → MCP (via extension MCP)
Dans VSCode :

. Ouvre MCP: Show View
. Vérifie que netdata apparaît
. Clique sur Start

Résultat attendu :

. Logs visibles
. Capacités listées
. Requêtes testables

   🔹 Test 3 — MCP → Linux (NAS)
Depuis VSCode, envoie une requête :
GET /metrics
Résultat attendu :

. Retour JSON avec CPU, RAM, etc.
. Pas d’erreur de connexion
. Logs du serveur MCP montrent la requête reçue
. Les données correspondent à ce que le NAS expose

🟩 Conclusion : ce que tu obtiens
✔️ Un projet MCP propre, centralisé, NAS‑centré
✔️ Un serveur MCP hébergé sur SebInfraNAS
✔️ Une communication Windows → NAS → MCP
✔️ Une structure durable, documentée, évolutive
✔️ Une base solide pour Atelier I / II / III

Ce plan technique te guide pas à pas pour relancer ton projet MCP dans les meilleures conditions. En suivant ces étapes, tu reconstruis un environnement stable, propre et prêt à évoluer vers les prochaines étapes de ton apprentissage.
