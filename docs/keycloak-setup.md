# Keycloak Setup — IAM (OIDC + MFA)

## Objectif

Déployer Keycloak comme fournisseur d'identité central du lab Zero Trust : récupérer les utilisateurs depuis SRV-AD1 via fédération LDAP, ajouter une couche MFA, puis exposer l'authentification en OIDC pour SRV-WEB.

## Informations générales

| Élément | Valeur |
|---|---|
| Rôle | IAM — fédération LDAP + OIDC + MFA |
| Source d'identité | SRV-AD1 (Active Directory) |
| Consommateur | SRV-WEB (NGINX + OAuth2 Proxy) |

## Installation

Déploiement recommandé via Docker :

```bash
docker run -d --name keycloak \
  -p 8443:8443 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=<changeme> \
  -v keycloak_data:/opt/keycloak/data \
  quay.io/keycloak/keycloak:latest \
  start --https-certificate-file=/certs/tls.crt --https-certificate-key-file=/certs/tls.key
```

> Certificat HTTPS émis par SRV-PKI (voir [`pki-setup.md`](pki-setup.md)) à monter dans le conteneur.

## Fédération LDAP avec SRV-AD1 (récupération des utilisateurs)

Configuration dans **Realm Settings > User Federation > Add LDAP provider** :

| Paramètre | Valeur |
|---|---|
| Vendor | Active Directory |
| Connection URL | `ldaps://<IP-SRV-AD1>:636` |
| Bind Type | simple |
| Bind DN | compte de service dédié (lecture seule) |
| Users DN | ex. `OU=Users,DC=zt,DC=lab` |
| Username LDAP attribute | `sAMAccountName` |
| RDN LDAP attribute | `cn` |
| UUID LDAP attribute | `objectGUID` |
| Edit Mode | READ_ONLY (Keycloak ne doit pas modifier l'AD) |

**Étapes** :
1. Créer le compte de service en lecture seule sur SRV-AD1 (voir [`ad-setup.md`](ad-setup.md))
2. Renseigner la connexion LDAPS dans Keycloak avec le certificat de la PKI approuvé
3. Tester la connexion (`Test connection` puis `Test authentication`)
4. Lancer une **synchronisation complète** (`Synchronize all users`) pour importer les comptes existants
5. Activer une synchronisation périodique (`Periodic Full Sync` ou `Periodic Changed Users Sync`) pour garder les comptes à jour sans resynchroniser manuellement

## Mapping des attributs

Vérifier le mapping des attributs LDAP vers les attributs Keycloak (email, prénom, nom) dans l'onglet **Mappers** du provider LDAP, pour que les utilisateurs importés soient complets côté Keycloak.

## Activation du MFA

Une fois les utilisateurs importés depuis l'AD :
- Réaliser une **Authentication Flow** dédiée (copie du flow *Browser* par défaut) ajoutant une étape OTP (`OTP Form`) après l'authentification LDAP
- Assigner ce flow comme flow de navigateur par défaut du realm
- Les utilisateurs configurent leur MFA (TOTP) à la première connexion, ou via une action requise (`Configure OTP`) assignée en masse

## Exposition en OIDC vers SRV-WEB

- Créer un **client OIDC** dans Keycloak pour SRV-WEB (type confidentiel, avec secret client)
- Configurer les URIs de redirection correspondant à OAuth2 Proxy
- Le secret client généré ne doit jamais être versionné en clair (voir `.gitignore`)

## Points de vigilance

- Le compte de service LDAP utilisé par Keycloak doit être en lecture seule et à privilèges strictement minimaux côté AD
- LDAPS obligatoire (pas de LDAP en clair) pour respecter le principe de chiffrement systématique du Zero Trust
- Les secrets clients OIDC et le mot de passe admin Keycloak ne doivent jamais être commités — voir `.gitignore`
- Documenter ici le nom exact du realm et du client OIDC créés une fois la configuration stabilisée

---

*Voir aussi [`ad-setup.md`](ad-setup.md) pour la source LDAP, [`pki-setup.md`](pki-setup.md) pour les certificats, et [`web-setup.md`](web-setup.md) pour la consommation côté reverse proxy.*
