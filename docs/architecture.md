# Architecture — Zero Trust Lab

## Vue d'ensemble

Ce lab met en œuvre une architecture Zero Trust : chaque accès est authentifié et vérifié individuellement (utilisateur + MFA), sans confiance implicite basée sur la position réseau. Une PKI interne fournit les certificats, Active Directory reste la source d'identité, Keycloak centralise l'authentification (OIDC + MFA), et un reverse proxy authentifiant protège l'accès aux ressources.

## Schéma des flux

```
                 ┌──────────────┐
                 │   SRV-PKI    │
                 │    AD CS     │
                 └──────┬───────┘
                        │  émission de certificats
                        ▼
┌─────────────┐   LDAP/LDAPS   ┌─────────────┐
│  SRV-AD1    │◄──────────────►│  Keycloak   │
│ Active Dir. │                 │ OIDC + MFA  │
└─────────────┘                 └──────┬──────┘
                                      │
                                  OIDC / HTTPS
                                      │
                                      ▼
                              ┌──────────────┐
                              │   SRV-WEB    │
                              │ NGINX        │
                              │ OAuth2 Proxy │
                              └──────┬───────┘
                                     │  HTTPS authentifié
                                     ▼
                              ┌──────────────┐
                              │ Windows 11   │
                              │    Client    │
                              └──────────────┘
```

## Composants et rôles

| Composant | Rôle | Protocoles |
|---|---|---|
| SRV-PKI | Autorité de certification interne (AD CS) | Émission de certificats pour les services internes (Keycloak, NGINX, LDAPS) |
| SRV-AD1 | Source d'identité (utilisateurs, groupes) | LDAP/LDAPS vers Keycloak |
| Keycloak | IAM — fédère l'identité AD, applique le MFA, émet les jetons | LDAP/LDAPS (vers AD), OIDC/HTTPS (vers SRV-WEB) |
| SRV-WEB | Point d'entrée unique vers les ressources protégées | OIDC/HTTPS (vers Keycloak), HTTPS (vers le client) |
| Client Windows 11 | Poste utilisateur, initie les requêtes | HTTPS |

## Principe Zero Trust appliqué

- **Aucune confiance basée sur le réseau** : même connecté au LAN du lab, un client doit s'authentifier via Keycloak (OIDC) pour accéder aux ressources derrière SRV-WEB
- **MFA systématique** : Keycloak impose une seconde facteur d'authentification, pas seulement le mot de passe AD
- **Chiffrement de bout en bout** : LDAPS entre AD et Keycloak, HTTPS partout ailleurs, certificats émis par la PKI interne (pas d'auto-signés en usage courant)
- **Point de contrôle unique** : SRV-WEB (NGINX + OAuth2 Proxy) est le seul chemin d'accès aux ressources ; aucun accès direct aux services internes depuis le client

## Rôle de la PKI (SRV-PKI / AD CS)

La PKI interne émet les certificats utilisés par :
- Keycloak (HTTPS, et LDAPS côté client LDAP)
- SRV-WEB (HTTPS pour NGINX)
- Éventuellement le client Windows 11 (authentification par certificat, selon configuration retenue)

Cela évite le recours à des certificats auto-signés (non vérifiables) ou à des certificats publics (inutiles pour un lab interne), et permet de pratiquer la gestion d'une chaîne de confiance interne comme en entreprise.

## Isolation réseau et lien avec le SOC

Ce lab est hébergé sur **Proxmox**, sur le même serveur physique que le [SOC home lab](../soc-home-lab), mais sur un **bridge réseau totalement isolé** du bridge SOC. Aucune communication directe n'existe entre les deux par défaut.

La supervision par Wazuh (SOC) passe par un point de contrôle unique — une interface dédiée sur OPNsense — avec des règles limitées à la remontée de logs. Détail complet dans [`interconnexion-soc.md`](interconnexion-soc.md).

## Points d'attention pour la suite

- Définir précisément le mode d'authentification du client Windows 11 : certificat machine/utilisateur émis par la PKI, et/ou authentification via le portail OIDC de Keycloak
- Décider si des scénarios offensifs (contournement MFA, abus de jetons OIDC) seront testés sur ce lab — impacterait la structure du repo (ajout d'un dossier `attack-scenarios/`)

---

*Voir aussi [`pki-setup.md`](pki-setup.md), [`ad-setup.md`](ad-setup.md), [`keycloak-setup.md`](keycloak-setup.md), [`web-setup.md`](web-setup.md) et [`client-setup.md`](client-setup.md) pour le détail de chaque composant.*
