# Connexion SSH Propre au NAS Depuis VS Code (Win10 + Linux)

But:

- Ouvrir une session SSH fiable vers le NAS depuis le terminal VS Code.
- Standardiser une commande unique de connexion pour les prochaines sessions.

## Emplacement de cette doc (coherence)

Cette procedure couvre Win10 et Linux depuis le terminal VS Code.
Le fichier reste volontairement place dans le dossier:

- 06_Installation_Claude_Desktop_Win10
- (choix d emplacement historique pour centraliser la connexion SSH NAS)

## Methode validee sur ce poste

Constat de session:

- La commande ssh seule n est pas resolue dans PowerShell de ce poste.
- La commande ssh.exe fonctionne immediatement.

Commande de connexion operationnelle:

```powershell
ssh.exe SebInfraNAS
```

Prompt attendu apres connexion:

```bash
[SebAdminNAS@SebInfraNAS ~]$
```

## Connexion rapide (a lancer a chaque fois)

Dans le terminal integre VS Code:

```powershell
ssh.exe SebInfraNAS
```

Sous Linux (terminal bash), utiliser:

```bash
ssh SebInfraNAS
```

Ou en direct sans alias:

```bash
ssh SebAdminNAS@seb-infra-nas
```

## Connexion durable (configuration OpenSSH Windows)

Objectif:

- Garder un alias lisible et stable.

1. Ouvrir le fichier de config SSH utilisateur:

```powershell
notepad $HOME\.ssh\config
```

2. Ajouter ou verifier ce bloc:

```sshconfig
Host SebInfraNAS
    HostName seb-infra-nas
    User SebAdminNAS
    Port 22
```

3. Tester la connexion:

```powershell
ssh.exe SebInfraNAS
```

## Connexion durable (configuration OpenSSH Linux)

Objectif:

- Avoir le meme alias lisible `SebInfraNAS` sous Linux.

1. Ouvrir le fichier de config SSH utilisateur:

```bash
nano ~/.ssh/config
```

2. Ajouter ou verifier ce bloc:

```sshconfig
Host SebInfraNAS
    HostName seb-infra-nas
    User SebAdminNAS
    Port 22
```

3. Appliquer les permissions attendues:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
```

4. Tester la connexion:

```bash
ssh SebInfraNAS
```

## Verification de connexion propre

Apres connexion:

1. Verifier l hote

```bash
hostname
```

2. Verifier l utilisateur actif

```bash
whoami
```

3. Verifier le repertoire courant

```bash
pwd
```

Si tout est bon:

- hostname renvoie SebInfraNAS (ou nom equivalent NAS)
- whoami renvoie SebAdminNAS

## Fermeture propre de session

```bash
exit
```

## Depannage court

Cas 1 - Message: ssh n est pas reconnu

- Utiliser ssh.exe au lieu de ssh.

Cas 2 - Message: Could not resolve hostname SebInfraNAS

- Verifier le bloc Host dans $HOME\.ssh\config
- Tester temporairement par nom DNS direct:

```powershell
ssh.exe SebAdminNAS@seb-infra-nas
```

Cas 3 - Message: Permission denied

- Verifier l utilisateur dans la config SSH
- Verifier le mot de passe/cle cote NAS

Cas 4 - Sous Linux: `ssh.exe` non reconnu

- C est normal: sous Linux la commande est `ssh` (sans `.exe`).
- Exemple: `ssh SebInfraNAS`

## Option PuTTY (si prefere)

Commande directe:

```powershell
putty.exe -ssh SebAdminNAS@seb-infra-nas -P 22
```

Commande avec session sauvegardee:

```powershell
putty.exe -load "SebInfraNAS"
```

## Routine de reprise recommandee

1. Ouvrir VS Code
2. Ouvrir terminal integre
3. Lancer la commande selon l OS:
    - Win10 PowerShell: `ssh.exe SebInfraNAS`
    - Linux bash: `ssh SebInfraNAS`
4. Verifier rapidement hostname et whoami
5. Commencer le chantier (Docker, Authelia, Netdata)
