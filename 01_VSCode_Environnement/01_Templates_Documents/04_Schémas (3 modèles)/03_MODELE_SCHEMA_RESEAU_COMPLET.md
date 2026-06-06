📄 3. MODELE_SCHEMA_RESEAU_COMPLET.md
(Architecture réseau complète — version PRO, idéale pour ton QG 2056)

# 🌐 Schéma Réseau Complet — Architecture ${1:Nom}

> **Auteur :** Sébastien
> **Dernière mise à jour :** ${CURRENT_DATE}
> **Version :** ${2:1.0}

---

## 🎯 Objectif

${3:Décrire l’objectif du schéma global (ex : architecture complète du réseau domestique 2026).}

---

## 🧩 Vue d’ensemble

${4:Description générale de l’architecture.}

---

## 🏗️ Schéma principal (Mermaid)

```mermaid
graph TD;
    WAN[${5:Fibre / WAN}] --> R[${6:Routeur Principal}]
    R --> S1[${7:Switch Principal}]
    S1 --> NAS[${8:NAS}]
    S1 --> PC1[${9:PC Bureau}]
    S1 --> PC2[${10:PC Portable}]
    S1 --> AP1[${11:Point d'accès WiFi}]
    AP1 --> TEL[${12:Smartphone}]
    AP1 --> TAB[${13:Tablette}]
    S1 --> TV[${14:TV / Box}]

## 🧱 Variante ASCII

${15:Ajouter ici une version ASCII si nécessaire.}

🔧 Détails techniques
Plage IP : ${16:192.168.1.0/24}

DHCP : ${17:Activé / Désactivé}

DNS : ${18:DNS opérateur / custom}

VLAN : ${19:Liste des VLAN si applicable}

## 📝 Notes complémentaires
${20:Remarques, limites, évolutions prévues.}

Code

---

# 🟢 **D_SCHEMAS est terminé.**
