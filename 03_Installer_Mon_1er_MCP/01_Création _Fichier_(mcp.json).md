🟦 1) Installation du MCP hello (dans Atelier I)
Ce MCP est parfait pour découvrir :

- comment un serveur MCP apparaît dans VSCode
- comment il se lance
- comment il expose ses capacités
- comment il s’intègre dans un profil

Et surtout :
👉 il est simple, stable, sans risque, idéal pour tester.

🟩 Étape A — Ouvrir la configuration MCP de Atelier I
Ouvre VSCode avec Atelier I

Va dans :
Paramètres → Profils → Atelier I Général — SébCore

Descends jusqu’à :
Serveurs MCP

Clique sur :
Configurer

VSCode va ouvrir (ou créer) ton fichier de configuration MCP.

🟩 Étape B — Ajouter le serveur MCP hello
Dans le fichier ouvert, ajoute ceci :

json
{
  "mcpServers": {
    "hello": {
      "command": "npx",
      "args": ["@modelcontextprotocol/hello-mcp"]
    }
  }
}
Puis sauvegarde.

🟩 Étape C — Lancer le serveur
Après la sauvegarde :

- VSCode détecte le serveur
- Il te propose de le lancer
- Tu verras un nouvel onglet “MCP” dans la barre latérale
- Tu verras “hello” dans la liste des serveurs actifs

Tu peux cliquer dessus pour voir :

- les logs
- les capacités
- les requêtes possibles
- les réponses du serveur

👉 Tu viens d’installer ton premier MCP.
