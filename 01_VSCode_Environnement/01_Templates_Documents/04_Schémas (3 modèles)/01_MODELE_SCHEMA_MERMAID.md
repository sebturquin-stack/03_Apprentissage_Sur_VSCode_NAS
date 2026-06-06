📄 1. MODELE_SCHEMA_MERMAID.md
+(Schéma réseau — format Mermaid)

## 🏗️ Schéma Réseau (Mermaid)

> **Auteur :** Sébastien
> **Dernière mise à jour :** ${CURRENT_DATE}
> **Version :** ${1:1.0}

---

## 🎯 Objectif

${2:Décrire l’objectif du schéma (ex : architecture réseau domestique, topologie WiFi, etc.).}

---

## 📘 Schéma Mermaid

```mermaid
graph TD;
    A[${3:Routeur}] --> B[${4:Switch Principal}]
    B --> C[${5:NAS}]
    B --> D[${6:PC Bureau}]
    B --> E[${7:Point d'accès WiFi}]
    E --> F[${8:Smartphone}]
    E --> G[${9:Tablette}]

📝 Notes
${10:Ajouter des remarques, variantes, ou versions alternatives.}

---


