# Analyse complete de stabilisation de netdata-nas sur SebInfraNAS

Date de reference: 2026-06-25
Contexte: NAS SebInfraNAS (QNAP TS-264)

## 1. Verification de la RestartPolicy

Constat:

- La RestartPolicy du conteneur netdata-nas est valide et conforme a l objectif de continuite de service.
- Le conteneur est configure pour redemarrer automatiquement en cas d arret non volontaire.

Conclusion:

- Verification RestartPolicy: OK.

## 2. Verification du port 19999

Constat:

- Le service Netdata expose correctement son port interne 19999.
- L acces de supervision est operationnel via le mapping defini sur le NAS.

Conclusion:

- Verification port 19999: OK.

## 3. Verification du volume netdata_data

Constat:

- Le volume actif de netdata-nas est netdata_data.
- Le Mountpoint reel observe pour ce volume est celui de la structure Docker de Container Station sur le NAS.
- Un doublon de dossier de type container-station-data/container-station-data a ete observe dans l arborescence de stockage.

Explication:

- Lors de la reinstallation de Container Station, le moteur Docker du NAS a recree automatiquement certains dossiers de travail et de metadata.
- Ce comportement peut produire des chemins redondants (dossiers imbriques au nom similaire) sans invalider le volume actif utilise par le conteneur stable.

Conclusion:

- Volume netdata_data: valide et exploitable.

## 4. Analyse des logs Netdata

Constat:

- Des messages Permission denied apparaissent dans les logs.
- Ces messages concernent des processus ou zones systeme proteges sur QNAP.
- Le mecanisme de protection (dont AppArmor) limite l acces de certains collecteurs Netdata a des ressources sensibles.

Interpretation:

- Ces erreurs sont attendues dans ce contexte NAS et n indiquent pas une panne du conteneur.
- Aucun signal de crash-loop, de redemarrage anormal en chaine, ni de degradation du statut healthy n a ete releve.

Conclusion:

- Logs: anomalies normales sur plateforme QNAP, sans impact sur la stabilite du conteneur.

## 5. Verification du chemin local

Constat:

- Une commande ls a echoue pendant les controles.
- L echec provenait d un chemin cible qui ne correspondait pas au Mountpoint reel du volume netdata_data.

Interpretation:

- Il s agit d un ecart de chemin lors de la verification manuelle, pas d une corruption du volume.

Conclusion:

- Le controle local est coherent apres correction vers le Mountpoint reel.

## 6. Conclusion generale de stabilisation

Etat de synthese:

- netdata-nas est stable et healthy.
- Les erreurs Permission denied observees sont normales sur QNAP.
- Le volume netdata_data est valide.
- Le NAS est propre apres suppression du conteneur fantome 01_Netdata et de son volume associe mcp-netdata_netdata_data.
- Le comportement de Container Station (recreation de dossiers avec doublons de chemin) est documente comme point d attention operationnel.

Decision:

- Stabilisation confirmee.
- Monitoring NAS exploitable dans un cadre de production personnelle.

STABILISATION_NETDATA_NAS_OK
