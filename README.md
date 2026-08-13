# Zero Trust Lab

Lab de sécurité personnel pour la mise en pratique d'une architecture Zero Trust : PKI interne, gestion d'identité centralisée (Keycloak/OIDC), authentification forte (MFA), et reverse proxy authentifiant.

## 🎯 Objectifs

- Mettre en œuvre les principes Zero Trust (vérification systématique, moindre privilège, aucune confiance implicite basée sur le réseau) sur une infrastructure réaliste
- Pratiquer l'intégration PKI ↔ AD ↔ IAM (Keycloak) ↔ reverse proxy ↔ client
- Faire superviser cette architecture par le SOC (Wazuh) déjà en place sur un lab séparé, en gardant une segmentation réseau stricte

##  Architecture

```
                 ┌──────────────┐
                 │   SRV-PKI    │
                 │    AD CS     │
                 └──────┬───────┘
                        │
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
                                     │
                                     ▼
                              ┌──────────────┐
                              │ Windows 11   │
                              │    Client    │
                              └──────────────┘
```

> Schéma détaillé, flux et choix réseau dans [`docs/architecture.md`](docs/architecture.md)

## 🧰 Composants

| Composant | Rôle |
|---|---|
| SRV-PKI | Autorité de certification interne (AD CS) |
| SRV-AD5 | Active Directory, source d'identité |
| Keycloak | IAM — authentification OIDC + MFA |
| SRV-WEB | Reverse proxy authentifiant (NGINX + OAuth2 Proxy) |
| Client Windows 11 | Poste utilisateur final |

## 🌐 Infrastructure

Hébergé sur **Proxmox**, sur le même serveur physique que le [SOC home lab](../soc-home-lab), mais sur un **bridge réseau totalement isolé**. La communication entre les deux labs passe par un point de contrôle unique (OPNsense du SOC) — voir [`docs/interconnexion-soc.md`](docs/interconnexion-soc.md).

## ✅ État d'avancement

- [x] Architecture définie (PKI, AD, Keycloak, reverse proxy, client)
- [ ] Déploiement SRV-PKI (AD CS)
- [ ] Déploiement SRV-AD1
- [ ] Déploiement et configuration Keycloak (OIDC + MFA)
- [ ] Déploiement SRV-WEB (NGINX + OAuth2 Proxy)
- [ ] Enrôlement du client Windows 11
- [ ] Interconnexion avec le SOC pour supervision Wazuh

## 🔗 Lien avec le SOC

Le SOC (Wazuh) doit superviser les événements de ce lab Zero Trust (authentifications, échecs MFA, anomalies OIDC) sans que les deux réseaux soient fusionnés. Le flux passe par une interface dédiée sur OPNsense, avec des règles de pare-feu restreintes au strict nécessaire (remontée des logs vers Wazuh uniquement).

## ⚠️ Note

Ce lab est un environnement **isolé à usage pédagogique**. Les configurations partagées ici sont nettoyées de tout secret ou mot de passe réel — voir `.gitignore` (certificats/clés PKI, secrets clients OIDC, cookie secret OAuth2 Proxy notamment).
