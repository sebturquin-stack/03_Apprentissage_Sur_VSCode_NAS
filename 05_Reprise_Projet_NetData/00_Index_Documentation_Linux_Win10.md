# Index Documentation Linux + Win10 - Projet MCP Netdata

Objectif:

- Garder une documentation claire, duale et evolutive.
- Eviter les doublons inutiles.
- Permettre une reprise rapide selon l OS utilise.

## Principe simple

- Linux: base technique de reference (deja en place).
- Win10: adaptation pratique de la meme logique.
- Commun: conserver un tronc commun pour les concepts qui ne dependent pas de l OS.

## Arborescence conseillee

- 01_Organisation_NAS: commun
- 02_Config_Container: commun (avec notes Linux/Win10 dans les fichiers)
- 03_Installation_Claude_Desktop_Linux_Debian: specifique Linux
- 04_Container_MCP_Claude-Desktop_CONNECTE: commun (diagnostic et resolution)
- 05_Grosse_Feuille_De_Route: commun (ordre des chantiers)
- 06_Installation_Claude_Desktop_Win10: specifique Win10

## Regle de redaction (anti-chaos)

1. Un sujet = un fichier principal
2. Si seule une commande change selon l OS: garder un seul fichier et separer en sous-sections Linux/Win10
3. Si toute la procedure change: faire 2 fichiers distincts (Linux et Win10)
4. Toujours terminer un fichier par une section Verifications
5. Toujours indiquer la Prochaine action en fin de session

## Methode pour migrer la doc existante vers le mode dual

Etape 1 - Identifier le type du document

- Type A: concept commun
- Type B: procedure OS-specifique

Etape 2 - Choisir la forme

- Type A: rester dans le dossier commun
- Type B Linux: rester dans 03_...
- Type B Win10: creer/ecrire dans 06_...

Etape 3 - Lier les documents

- Ajouter dans chaque fichier un bloc Voir aussi vers l equivalent Linux ou Win10

Etape 4 - Valider avec une checklist

- Le lecteur sait quoi faire sans connaissance implicite
- Les commandes sont testables telles quelles
- Les chemins sont explicites

## Demarrage quotidien (routine)

Debut:

1. Lire les 2 dernieres entrees du journal
2. Lire la Prochaine action
3. Ouvrir le fichier du chantier du jour

Fin:

1. Completer le journal de session
2. Mettre a jour la Prochaine action
3. Ajouter un lien vers la preuve (capture/log) si besoin

## Dossier Win10 (demarrage demain)

Point d entree:

- 06_Installation_Claude_Desktop_Win10/01_README_Claude_Desktop_Win10.md

Objectif du jour 1 Win10:

- Poser les prerequis
- Verifier Docker Desktop
- Valider la connexion MCP
- Produire un premier journal de session Win10

## Liens utiles deja en place

- Journal de session: 03_Installation_Claude_Desktop_Linux_Debian/07_Journal_Session_Express_MCP_Netdata.md
- Procedure pas a pas journal: 03_Installation_Claude_Desktop_Linux_Debian/08_Procedure_Pas_A_Pas_Journal_MCP_Netdata.md
- Guide setup aliases/watchdog: 03_Installation_Claude_Desktop_Linux_Debian/04_Guide_Setup_MCP_Watchdog_Aliases.md

## Decision prise

- Linux reste la reference technique initiale.
- Win10 devient une piste parallele documentee proprement dans 06_...
- Les elements communs restent au meme endroit pour ne pas dupliquer.
