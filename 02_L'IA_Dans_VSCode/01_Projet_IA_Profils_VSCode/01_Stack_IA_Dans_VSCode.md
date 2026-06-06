Tu touches exactement le bon sujet, et tu as raison d’être exigeant là‑dessus.
Bien intégrée, l’IA dans VSCode, c’est un deuxième cerveau branché sur ton éditeur.
Vu comment tu utilises déjà les snippets, on va te construire un setup IA au même niveau de rigueur.

Je te propose un plan en plusieurs blocs, comme pour Markdown, mais orienté usage réel plutôt que blabla marketing.

1. Objectif de ton “stack IA dans VSCode”
But :
Que ton environnement dev / doc devienne :

centré sur toi (tes projets, ton style, tes snippets, ton QG)

pilotable au clavier (comme tu aimes : Ctrl+Espace, palette, raccourcis)

cohérent : mêmes réflexes partout (chat, inline, refactor, doc, tests)

au service de ton flux (pas un gadget qui spamme des suggestions)

On va donc viser :

Copilot (ou équivalent) pour :

complétion inline

chat contextuel dans l’éditeur

actions ciblées (expliquer, refactor, générer, tester)

Paramétrage fin pour :

ne pas te polluer

garder le contrôle

coller à ta façon de travailler (snippets, Markdown, réseau, infra)

2\. Étape 1 — Vérifier / installer l’IA dans VSCode
On part sur GitHub Copilot + Copilot Chat, qui sont aujourd’hui la référence dans VSCode.

À faire :

Ouvrir les extensions.
Ctrl+Shift+X → chercher :

“GitHub Copilot”

“GitHub Copilot Chat”

Installer les deux.

Te connecter à GitHub.

Ctrl+Shift+P → GitHub: Sign in.

Suivre le navigateur.

Quand ça, c’est fait, tu me dis juste :

“Copilot + Chat installés et connectés.”

Et on passe à la configuration fine.

3\. Étape 2 — Activer seulement ce qui t’est utile
On ne veut pas un truc qui te spamme, on veut un outil précis.

Dans Paramètres (Ctrl+,) → chercher “Copilot”.

Je te propose ce réglage de base :

Inline suggestions :

ON pour les langages techniques (YAML, JSON, scripts, infra, etc.)

OFF pour markdown si tu veux garder la main sur ta doc
(ou ON si tu veux qu’il t’aide à rédiger)

Code actions / refactor :

github.copilot.editor.enableCodeActions → true

Chat visible :

chat.commandCenter.enabled → true (menu Chat en haut)

On fera ensuite un profil “Sébastien” de bonnes pratiques : quand l’utiliser, quand l’ignorer, comment le guider.

4\. Étape 3 — Les 3 usages IA que je veux te rendre naturels
On va caler 3 réflexes IA dans ton workflow, comme tu as fait avec Ctrl+Espace pour les snippets.

3.1. Complétion inline (le “ghost text”)
Usage typique :

tu commences une liste, un tableau, une procédure, un bloc de code

l’IA te propose la suite en gris

tu :

TAB → tu acceptes.

Échap → tu refuses.

On l’utilisera pour :

générer des variantes de fiches techniques

compléter des sections répétitives

proposer des exemples de config réseau, scripts, etc.

3.2. Chat dans l’éditeur (inline chat)
Raccourci par défaut : Ctrl+I (inline chat).

Usage typique :

tu sélectionnes un bloc (config, doc, code, schéma)

tu fais inline chat

tu demandes :

“Explique ce bloc”

“Propose une version plus claire”

“Génère la version pour un autre appareil”

“Transforme ça en procédure pas à pas”

C’est là que ça devient ton assistant contextuel dans VSCode.

3.3. Vue Chat (panneau dédié)
Raccourci : Ctrl+Alt+I → ouvre la vue Chat.

Usage typique :

tu bosses sur un projet réseau

tu veux :

un plan de migration

une checklist

un script

une structure de dossier

tu discutes avec l’IA en gardant ton workspace ouvert.

C’est ton “grand tableau blanc” IA, complémentaire à moi dans cette fenêtre‑ci.

5\. Étape 4 — Faire parler l’IA avec tes modèles
Là où tu vas vraiment exploser en puissance, c’est quand tu vas :

coller un de tes modèles (README, Fiche, Procédure, Projet, etc.)

dire à l’IA dans VSCode :

“Génère la fiche pour ce nouvel appareil à partir de ce modèle”

“Remplis cette procédure à partir de ce log / de ce scénario”

“Propose un schéma Mermaid pour cette topologie”

“Complète ce dossier projet pour ce nouveau cas”

Et surtout, tu peux lui dire :

“Respecte strictement ce format : …”
“N’invente pas, utilise uniquement les infos de ce fichier.”
“Ne modifie pas les titres, seulement le contenu.”

On pourra même se faire des prompts modèles pour ça.

6\. Étape 5 — Ce que je te propose maintenant
On reste dans ta logique :
1 snippet → tu testes → tu comprends → on passe au suivant.

Version IA :

Étape 1 concrète :
Tu vérifies / installes :

GitHub Copilot

GitHub Copilot Chat
(et tu te connectes)

Tu reviens me dire :

“C’est bon, Copilot + Chat sont installés.”

Ensuite, on fera ensemble, comme pour Markdown :

un profil de réglages (qu’on pourra documenter dans ton QG)

une fiche “Raccourcis IA VSCode — Sébastien”

un premier cas d’usage réel :

par exemple : “Génère une fiche technique Appareil réseau à partir d’un ping + un nmap + ton modèle”

Si tu veux, on commence ultra simple :
prochaine étape : tu me confirmes l’état actuel :

Tu as déjà Copilot installé ?

Tu as déjà la vue Chat dans VSCode ?

Tu me dis où tu en es, et on construit étape par étape, comme tu l’as demandé.
Commen
