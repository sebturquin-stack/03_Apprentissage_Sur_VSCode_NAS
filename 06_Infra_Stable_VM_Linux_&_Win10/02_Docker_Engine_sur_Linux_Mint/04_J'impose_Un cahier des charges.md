# Cahier Des Charges Officiel - SebNet-LAN-2.5G

## Objet

Ce document fixe la logique structurelle officielle de l'infrastructure SebNet-LAN-2.5G pour les services de monitoring et de gestion Docker.

Objectifs:

- imposer une convention de nommage stable et lisible;
- distinguer clairement dossiers logiques NAS et dossiers physiques locaux;
- normaliser permissions, proprietaires et emplacements;
- fournir une base documentaire durable pour Netdata, Portainer et Dockge.

## Convention De Nommage

Format obligatoire:

- `NN_NomDuDossier`

Regles:

- `NN` = numero sur deux chiffres;
- majuscule initiale sur chaque mot utile;
- underscore `_` comme separateur;
- aucun espace;
- aucun accent;
- aucun caractere special hors underscore.

Exemples conformes:

- `01_Monitoring`
- `01_Netdata`
- `02_Portainer`
- `03_Dockge`

Exemples non conformes:

- `netdata`
- `01 netdata`
- `01-Netdata`
- `01_Netdata Docs`

## Deux Types De Dossiers

### 1. Dossiers Logiques NAS

Emplacement officiel:

- `/InfraData/05_Infra/01_Monitoring/`

Role:

- documentation;
- captures;
- README;
- historique;
- notes de maintenance;
- traces manuelles d'exploitation.

Structure officielle:

```text
/InfraData/05_Infra/01_Monitoring/
├── README.md
├── 01_Netdata/
│   └── README.md
├── 02_Portainer/
│   └── README.md
└── 03_Dockge/
    └── README.md
```

Permissions cibles NAS:

```bash
sudo chmod -R 770 /InfraData/05_Infra/01_Monitoring
```

### 2. Dossiers Physiques Locaux

Emplacements officiels:

- `/opt/portainer`
- `/opt/dockge`

Role:

- volumes Docker;
- donnees runtime;
- fichiers de service;
- donnees persistantes locales;
- isolation des services critiques hors NAS.

Permissions cibles local Linux:

```bash
chmod 770 /opt/portainer /opt/dockge
chown root:docker /opt/portainer /opt/dockge
```

## Regles De Coherence

- Les dossiers logiques NAS doivent toujours etre crees avant la documentation d'un nouveau service.
- Les dossiers physiques locaux doivent etre choisis en fonction de la stabilite d'exploitation, pas de la convention visuelle du NAS.
- Un service peut avoir un dossier logique et un dossier physique distincts.
- Le README logique doit toujours documenter le lien vers l'emplacement physique reel.

## Cas Particulier Netdata

Le dossier `netdata` deja present dans `/InfraData/05_Infra/` reste un artefact physique historique cree par Docker.

Regle officielle:

- ne pas renommer ce dossier historique sans migration explicite;
- utiliser `01_Netdata` comme dossier logique officiel de documentation;
- documenter dans le README Netdata la difference entre dossier logique et dossier physique historique.

## Commandes Officielles De Mise En Place

### Dossiers Logiques NAS

```bash
sudo mkdir -p /InfraData/05_Infra/01_Monitoring/01_Netdata
sudo mkdir -p /InfraData/05_Infra/01_Monitoring/02_Portainer
sudo mkdir -p /InfraData/05_Infra/01_Monitoring/03_Dockge

sudo chmod -R 770 /InfraData/05_Infra/01_Monitoring
```

### Dossiers Physiques Locaux Linux

```bash
mkdir -p /opt/portainer
mkdir -p /opt/dockge

chmod 770 /opt/portainer /opt/dockge
chown root:docker /opt/portainer /opt/dockge
```

## Services Couverts Par Cette V1

- `01_Netdata`
- `02_Portainer`
- `03_Dockge`

## Validation Attendue

Une mise en place est consideree conforme si:

- les dossiers logiques sont presents sous `/InfraData/05_Infra/01_Monitoring/`;
- chaque dossier logique contient un `README.md`;
- les emplacements physiques sont documentes sans ambiguite;
- les permissions cibles sont ecrites noir sur blanc;
- la convention `NN_NomDuDossier` est respectee partout dans la couche logique.

## Historique Des Versions

- `2026-06-20` - `v1.1` - correction du bloc NAS: ajout de `sudo` et suppression du `chown` dans la procedure officielle.
- `2026-06-20` - `v1.0` - formalisation officielle de la logique structurelle SebNet-LAN-2.5G pour Netdata, Portainer et Dockge.
