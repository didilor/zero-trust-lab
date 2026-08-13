# Active Directory Setup — SRV-AD1

## Objectif

Déployer un contrôleur de domaine Active Directory servant de source d'identité unique pour le lab Zero Trust, fédérée ensuite par Keycloak via LDAP/LDAPS.

## Informations générales

| Élément | Valeur |
|---|---|
| Nom du serveur | SRV-AD1 |
| Rôle | Contrôleur de domaine, source d'identité |
| Consommateur principal | Keycloak (fédération LDAP/LDAPS) |

> Ce contrôleur de domaine est distinct de celui du SOC (`m21.lab` / SRV-AD1) — les deux labs restent sur des annuaires séparés, reliés uniquement via la supervision Wazuh (voir [`interconnexion-soc.md`](interconnexion-soc.md)), pas par une fédération d'annuaire.

## Installation du rôle AD DS

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName "<nom-du-domaine-zt>" -DomainNetbiosName "<NETBIOS>"
```

> Choisir un nom de domaine distinct de `m21.lab` pour éviter toute confusion entre les deux labs (ex : `zt.lab`).

## Rôle vis-à-vis de Keycloak

SRV-AD5 sert de fournisseur d'identité (Identity Provider LDAP) pour Keycloak :
- Keycloak interroge l'AD en LDAP/LDAPS pour authentifier les utilisateurs (bind LDAP)
- L'AD reste la source de vérité pour les comptes utilisateurs et groupes
- Keycloak ajoute la couche MFA et gère l'émission des jetons OIDC, l'AD ne gérant que l'authentification de premier facteur

## LDAPS — chiffrement de la communication avec Keycloak

Le flux LDAP entre SRV-AD5 et Keycloak doit être chiffré (LDAPS, port 636) plutôt qu'en LDAP clair (port 389), conformément au principe Zero Trust de chiffrement systématique :
- Certificat serveur LDAPS émis par SRV-PKI (voir [`pki-setup.md`](pki-setup.md)) et installé sur le contrôleur de domaine
- Vérifier que le certificat racine de la PKI est bien approuvé côté Keycloak pour valider la chaîne de confiance

## Structure de l'annuaire

- Comptes utilisateurs et éventuels groupes à définir selon les scénarios de test prévus (accès simple vs accès avec rôles différenciés dans Keycloak)
- Structure à documenter ici une fois définie (OU, groupes, comptes de service)

## Compte de service pour Keycloak

Un compte de service dédié (bind LDAP en lecture seule) doit être créé pour Keycloak, avec des droits limités à la lecture de l'annuaire — pas de droits d'administration du domaine, conformément au principe de moindre privilège.

## Points de vigilance

- Aucun mot de passe, export d'annuaire (`ntds.dit`, ruches SAM/SECURITY) ne doit être versionné — voir `.gitignore`
- Le compte de service Keycloak doit rester à privilèges strictement minimaux
- Documenter ici le nom de domaine final retenu et la structure des comptes/groupes une fois le déploiement stabilisé

---

*Voir aussi [`architecture.md`](architecture.md) pour la place de l'AD dans le schéma global, et [`keycloak-setup.md`](keycloak-setup.md) pour la configuration de la fédération LDAP.*
