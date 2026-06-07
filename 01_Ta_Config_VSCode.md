🟦 PLAN GLOBAL — Configuration VSCode 2056
(On va suivre ce plan dans l’ordre, ce soir et demain)

Fondations techniques
Encodage, autosave, indentation, formatage, fichiers invisibles, minimap, etc.

Confort visuel & productivité
Thème, police JetBrains Mono, ligatures, rendu, curseur, highlight, navigation.

Markdown Pro
Extensions, prévisualisation, table des matières, linting, navigation interne.

PowerShell / scripting
Terminal intégré, exécution, coloration, IntelliSense, sécurité.

Navigation & Workspace
Arborescence, favoris, multi-root, dossiers QG, raccourcis intelligents.

Extensions essentielles
Les vraies, pas la liste de 200 trucs inutiles.

Automatisation & stabilité
Paramètres utilisateur, paramètres workspace, snippets, modèles.

🟩 BLOC 1 — Fondations techniques (on commence ici)

- C’est la base absolue.
- Si ça n’est pas propre, tout le reste devient instable.

On va régler :

. Encodage par défaut
. Autosave
. Formatage automatique
. Indentation
. Fin de ligne
. Fichiers invisibles
. Nettoyage automatique
. Sauvegarde des fichiers Markdown
. Timeline
. Terminal intégré

🟦 1. Encodage par défaut → UTF‑8 BOM
Tu as déjà mis ton README maître en UTF‑8 BOM.
Maintenant on configure VSCode pour que TOUS les nouveaux fichiers soient en UTF‑8 BOM.

👉 Ouvre Settings
Ctrl + ,

👉 Cherche :
files.encoding

👉 Mets :
Code
utf8bom
👉 Cherche :
files.autoGuessEncoding

Désactive-le.
Ça évite que VSCode “devine” mal l’encodage.

🟦 2. Autosave (sauvegarde automatique propre)
👉 Cherche :
files.autoSave

Mets :

Code
afterDelay
👉 Cherche :
files.autoSaveDelay

Mets :

Code
750
→ fluide, pas intrusif, parfait pour coder et documenter.

🟦 3. Formatage automatique (mais intelligent)
👉 Cherche :
editor.formatOnSave

Active.

👉 Cherche :
editor.formatOnPaste

Active.

👉 Cherche :
editor.formatOnType

Active.

Ça te garantit un code propre sans jamais te gêner.

🟦 4. Indentation (propre, stable, lisible)
👉 Cherche :
editor.tabSize

Mets :

Code
4
👉 Cherche :
editor.insertSpaces

Active.

→ cohérence totale entre tous tes fichiers.

🟦 5. Fin de ligne (Windows + Git + Markdown)
👉 Cherche :
files.eol

Mets :

Code
\lf
Pourquoi LF et pas CRLF ?
→ Markdown, GitHub, IA, scripts → LF est le standard moderne.

🟦 6. Fichiers invisibles (important pour ton QG)
👉 Cherche :
files.exclude

Ajoute :

Code
**/.DS_Store
**/Thumbs.db
**/*.tmp
**/*.bak
→ ton QG reste propre.

🟦 7. Timeline (pour éviter le bug d’hier)
👉 Cherche :
timeline.showView

Active.

👉 Cherche :
timeline.excludeSources

Vide la liste.

→ tu verras toutes les modifications.

🟦 8. Terminal intégré (PowerShell propre)
👉 Cherche :
terminal.integrated.defaultProfile.windows

Mets :

Code
PowerShell
👉 Cherche :
terminal.integrated.fontFamily

Mets :

Code
JetBrains Mono
👉 Cherche :
terminal.integrated.cursorStyle

Mets :

Code
line
→ terminal lisible, moderne, agréable.
