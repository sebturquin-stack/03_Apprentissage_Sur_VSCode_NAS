# README - Installation Claude Desktop + MCP Netdata sur Win10

But:

- Reproduire un flux stable cote Win10 sans casser la base Linux.
- Documenter chaque etape avec verifications concretes.

## Portee

Ce dossier contient uniquement les procedures specifiques Win10.
Les sujets communs restent dans les dossiers communs du projet.

## Plan de travail Win10 (J1)

1. Verifier prerequis Win10
2. Verifier Docker Desktop et moteur Linux containers
3. Verifier acces au workspace depuis VS Code
4. Configurer Claude Desktop pour le serveur MCP
5. Tester les outils MCP de base
6. Journaliser la session

## Checklist prerequis Win10

- Win10 a jour (minimum stable pour Docker Desktop)
- Docker Desktop installe et demarre
- WSL2 actif si utilise
- VS Code installe
- Acces aux fichiers du projet confirme
- Claude Desktop installe

## Verification rapide Docker

Commandes a lancer dans terminal Win10:

1. docker --version
2. docker ps
3. docker info

Attendu:

- Pas d erreur de connexion daemon
- Contexte docker fonctionnel

## Configuration MCP (principe)

Objectif:

- Faire pointer Claude Desktop vers le serveur MCP Netdata (conteneur ou process selon ton choix d exploitation Win10).

A documenter dans ce dossier:

- Le fichier de config exact utilise sous Win10
- La commande exacte de lancement MCP
- Les variables env appliquees (NETDATA_BASE_URL, timeout)

## Verification MCP minimale

Demander ensuite dans Claude:

1. get_netdata_info
2. get_cpu_snapshot

Attendu:

- Reponse outillee sans erreur network_error

## Journal de session Win10

A la fin de chaque session Win10:

- Creer une entree dans un journal Win10 dedie (a creer au prochain fichier)
- Noter 3 actions max, 1 blocage, 1 prochaine action

## Voir aussi

- Base Linux: ../03_Installation_Claude_Desktop_Linux_Debian/
- Journal Linux existant: ../03_Installation_Claude_Desktop_Linux_Debian/07_Journal_Session_Express_MCP_Netdata.md
- Procedure journal detaillee: ../03_Installation_Claude_Desktop_Linux_Debian/08_Procedure_Pas_A_Pas_Journal_MCP_Netdata.md
