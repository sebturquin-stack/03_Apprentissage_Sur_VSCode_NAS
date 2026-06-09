# Procedure pas a pas - Journal de session MCP Netdata

Objectif:

- Te permettre de suivre une session Linux/Win10 sans te perdre.
- Te faire pratiquer les actions toi-meme, de facon repetitive et claire.
- Garder une trace fiable en moins de 30 secondes au debut et a la fin de session.

Public cible:

- Niveau apprentissage (debutant a intermediaire)
- Utilisation dans VS Code terminal bash

Perimetre:

- Journal principal: 07_Journal_Session_Express_MCP_Netdata.md
- Commandes journal:
  - mcp-jstart
  - mcp-jlast
  - mcp-jnew

## 1) Regle simple a retenir

Tu as seulement 2 actions obligatoires:

1. Debut de session: lancer mcp-jstart
2. Fin de session: lancer mcp-jnew puis completer le bloc ajoute

Pendant la session:

- Rien d'obligatoire pour le journal.
- Tu travailles normalement sur ton sujet technique.

## 2) Prerequis (a faire une seule fois)

Cette partie est deja faite chez toi, mais on la garde pour reference.

Etape A - Installer/mettre a jour les alias

- Commande: bash mcp-netdata/setup_mcp_v2.sh
- Effet: ajoute les commandes mcp-jstart, mcp-jlast, mcp-jnew dans ~/.bashrc

Etape B - Recharger le shell

- Commande: source ~/.bashrc
- Effet: rend les commandes disponibles dans le terminal courant

Etape C - Verification rapide

- Commande: type mcp-jstart mcp-jlast mcp-jnew
- Attendu: le shell affiche que ce sont des alias/fonctions

Si la verification echoue:

- Ouvrir un nouveau terminal VS Code
- Refaire: source ~/.bashrc
- Refaire la verification

## 3) Workflow debut de session (obligatoire)

But:

- Appliquer la regle ultra simple: lire les 2 dernieres entrees avant d agir.

Action 1:

- Commande: mcp-jstart

Ce que fait la commande:

- Affiche un rappel de la regle
- Affiche les 2 dernieres entrees du journal
- Rappelle la commande de cloture mcp-jnew

Ce que tu dois faire juste apres:

- Lire les 2 entrees affichees
- Identifier la prochaine action deja notee
- Demarrer le travail technique

## 4) Workflow pendant la session (optionnel)

Aucune commande obligatoire.

Option utile:

- Commande: mcp-jlast
- Usage: si tu perds le fil, tu relis rapidement les 2 dernieres entrees

## 5) Workflow fin de session (obligatoire)

But:

- Toujours fermer proprement la session avec une entree complete.

Action 1 - Generer un bloc pre-rempli

- Commande: mcp-jnew
- Effet: ajoute en bas du journal un bloc avec date/heure + OS + machine

Action 2 - Completer les champs

- Ouvrir: 07_Journal_Session_Express_MCP_Netdata.md
- Remplacer tous les ____ par ton contenu

Methode de remplissage conseillee:

- Objectif de la session:
  - Une phrase courte, orientee resultat
- Ce que j ai fait:
  - 3 lignes max, verbes d action
- Resultat:
  - OK si objectif atteint
  - Partiel si avancee incomplete
  - Echec si objectif non atteint
- Blocage:
  - aucun si rien a signaler
  - sinon message d erreur brut (copie exacte)
- Prochaine action:
  - Une seule action, la plus concrete possible
- Commande cle:
  - la commande la plus utile pour reprendre vite
- Fichiers touches:
  - chemins courts et utiles

## 6) Exemple concret de fin de session

Exemple de contenu valide:

- Objectif de la session: verifier le flux debut/fin du journal automatise
- Ce que j ai fait:
  1. Lance mcp-jstart et lu les 2 dernieres entrees
  2. Fait mes tests techniques habituels
  3. Lance mcp-jnew puis complete le bloc
- Resultat: OK
- Blocage (si oui): aucun
- Prochaine action (1 seule): reprendre demain avec mcp-jstart puis valider AppArmor
- Commande cle (optionnel): mcp-jstart
- Fichier(s) touches (optionnel): 07_Journal_Session_Express_MCP_Netdata.md

## 7) Erreurs frequentes et correction

Cas 1 - mcp-jstart: command not found

- Cause: alias non charge dans le terminal
- Correction:
  1. source ~/.bashrc
  2. type mcp-jstart
  3. si KO, ouvrir un nouveau terminal VS Code

Cas 2 - mcp-jnew ajoute bien le bloc mais rien ne s affiche

- C est normal: la commande ecrit dans le fichier
- Ouvrir le journal et scroller en bas

Cas 3 - Plusieurs blocs vides consecutifs

- Cause: mcp-jnew lance plusieurs fois
- Correction: garder seulement le dernier bloc utile et supprimer les doublons

Cas 4 - Oubli de cloture de session

- Correction a la reprise:
  1. lancer mcp-jstart
  2. completer l entree manquante pour la session precedente
  3. reprendre ensuite la session en cours

## 8) Routine apprentissage conseillee (7 jours)

Jour 1 a Jour 3:

- Faire uniquement la discipline debut/fin (mcp-jstart + mcp-jnew)

Jour 4 a Jour 5:

- Soigner la qualite du champ Prochaine action

Jour 6 a Jour 7:

- Ajouter des commandes cles plus utiles pour reprise rapide

Objectif pedagogique:

- Construire un reflexe stable sans charge mentale

## 9) Resume ultra court (memo)

- Debut: mcp-jstart
- Pendant: rien d obligatoire
- Fin: mcp-jnew + je complete le bloc

Si tu fais ces 3 lignes a chaque session, ton suivi devient fiable et durable.
