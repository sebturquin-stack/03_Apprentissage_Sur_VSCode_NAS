# 📁 2. MODELE_DOSSIER_SERVICE.md

+(Pour documenter un service complet : DNS, DHCP, WiFi, NAS, sauvegarde, etc)

```markdown
# 🧰 Dossier Service — ${1:Nom du service}

> **Auteur :** Sébastien
> **Dernière mise à jour :** ${CURRENT_DATE}
> **Version :** ${2:1.0}
> **Statut :** ${3:Actif / Maintenance}

---

## 🎯 Objectif du service
${4:Décrire la fonction principale du service.}

---

## 🧩 Rôle dans l’infrastructure
${5:Expliquer comment ce service s’intègre dans ton réseau.}

---

## 🔗 Dépendances
- ${6:Service ou composant lié 1}
- ${7:Service ou composant lié 2}

---

## 📁 Structure recommandée du dossier

${1:Nom_du_service}/
│
├── README.md
├── 01_Configuration/
│     ├── config.md
│     └── historique.md
│
├── 02_Procedures/
│     ├── installation.md
│     ├── maintenance.md
│     └── incident.md
│
├── 03_Schemas/
│     └── schema_service.md
│
└── 04_Notes/
        └── notes.md

## ⚙️ Configuration du service
${8:Paramètres importants, fichiers de configuration, options.}

---

## 🧪 Tests & validation
${9:Procédure de test, critères de validation.}

---

## 📝 Notes complémentaires
${10:Remarques, limites, évolutions prévues.}


