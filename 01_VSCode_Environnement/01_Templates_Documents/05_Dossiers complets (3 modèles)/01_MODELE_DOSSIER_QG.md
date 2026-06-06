📁 1. MODELE_DOSSIER_QG.md
(Le modèle principal — celui qui structure un dossier complet du QG 2056)

# 📂 Dossier QG — ${1:Nom du dossier}

> **Auteur :** Sébastien
> **Dernière mise à jour :** ${CURRENT_DATE}
> **Version :** ${2:1.0}
> **Statut :** ${3:Actif / En cours / À revoir}

---

## 🎯 Objectif du dossier

${4:Décrire clairement l’objectif de ce dossier dans l’infrastructure.}

---

## 🧩 Rôle dans l’infrastructure

${5:Expliquer comment ce dossier s’intègre dans l’architecture globale.}

---

## 🔗 Dépendances internes

- ${6:Dossier ou service lié 1}
- ${7:Dossier ou service lié 2}
- ${8:Dossier ou service lié 3}

---

## 📁 Structure recommandée du dossier

${1:Nom_du_dossier}/
│
├── README.md
├── 01_Configuration/
├── 02_Documentation/
├── 03_Schemas/
├── 04_Procedures/
└── 05_Notes/

---

## 📘 Contenu attendu

${9:Décrire ce que doit contenir ce dossier.}

---

## 🧱 Schéma (optionnel)

```mermaid
graph TD;
    A[${10:Composant principal}] --> B[${11:Élément 1}]
    A --> C[${12:Élément 2}]
    A --> D[${13:Élément 3}]

## 📝 Notes complémentaires
${14:Remarques, limites, évolutions prévues.}
