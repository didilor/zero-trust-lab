# Web Setup — SRV-WEB (NGINX + OAuth2 Proxy)

## Objectif

SRV-WEB héberge la ressource protégée du projet **EYDIE-LAB** : une page présentant le projet Zero Trust, accessible uniquement après authentification complète via Keycloak (OIDC + MFA). NGINX sert la ressource, OAuth2 Proxy applique le contrôle d'accès, Keycloak réalise l'authentification.

## Architecture obtenue

```
 Poste Windows 11
       │
       │ HTTPS
       ▼
     NGINX
       │
       │ auth_request
       ▼
 OAuth2 Proxy
       │
       │ OIDC / HTTPS
       ▼
   Keycloak
       │
       │ LDAP/LDAPS
       ▼
Active Directory
```

**À retenir** : SRV-WEB est la ressource protégée, Keycloak réalise l'authentification, OAuth2 Proxy applique le contrôle d'accès, et NGINX sert la ressource uniquement après validation de l'identité.

## Composants installés

| Élément | Détail |
|---|---|
| Serveur web / reverse proxy | NGINX |
| Contrôle d'accès | OAuth2 Proxy v7.8.1 (Docker) |
| Fournisseur d'identité | Keycloak (OIDC) |
| Client Keycloak utilisé | `web-nginx` |
| Page servie | `/home/eydie/zero-trust/html/index.html` |
| URL de callback OIDC | `https://192.168.226.142/oauth2/callback` |

## Page web

Une page personnalisée présente le projet EYDIE-LAB et confirme visuellement que l'accès a été authentifié. Elle a été retravaillée pour ressembler à une véritable interface web plutôt qu'à une page de test brute, avec une identification claire du projet.

## OAuth2 Proxy

- Déployé en conteneur Docker (v7.8.1)
- Configuré avec Keycloak comme fournisseur OIDC, via le client `web-nginx`
- Le certificat TLS de Keycloak est placé côté OAuth2 Proxy pour lui permettre de vérifier la chaîne de confiance lors des échanges HTTPS avec Keycloak
- URL de callback : `https://192.168.226.142/oauth2/callback`, à faire correspondre exactement à l'URI de redirection déclarée côté client Keycloak (voir [`keycloak-setup.md`](keycloak-setup.md))

## Intégration NGINX ↔ OAuth2 Proxy

NGINX utilise la directive `auth_request` pour interroger OAuth2 Proxy avant de servir la ressource :

- Si l'utilisateur est authentifié (session OAuth2 Proxy valide) → NGINX sert la page protégée
- Si l'utilisateur n'est pas authentifié → redirection vers `/oauth2/sign_in`, qui redirige ensuite vers Keycloak pour authentification (LDAP + MFA)
- Après authentification réussie sur Keycloak → retour vers OAuth2 Proxy → retour vers NGINX → accès à la page protégée

Principe NGINX (schéma de configuration, à adapter aux chemins réels du déploiement) :

```nginx
location / {
    auth_request /oauth2/auth;
    error_page 401 = /oauth2/sign_in;
    # ... sert la page protégée si auth_request retourne 200
}

location /oauth2/ {
    proxy_pass http://oauth2-proxy:4180;
}
```

## Chiffrement

- **Client ↔ NGINX** : HTTPS
- **SRV-WEB ↔ Keycloak** : HTTPS, certificat émis par SRV-PKI, vérifié côté OAuth2 Proxy

## Parcours testé

Le parcours complet a été validé de bout en bout :

**Poste Windows → NGINX → OAuth2 Proxy → Keycloak → authentification → retour vers NGINX → page protégée**

## Points de vigilance

- Le secret du client OIDC `web-nginx` (côté OAuth2 Proxy) ne doit jamais être versionné en clair — voir `.gitignore` (`oauth2-proxy.cfg`, `cookie-secret*`)
- Le `cookie secret` d'OAuth2 Proxy (utilisé pour chiffrer les cookies de session) est également à exclure du repo
- Vérifier que l'URL de callback déclarée dans OAuth2 Proxy correspond exactement à celle enregistrée côté client Keycloak, sous peine d'échec de redirection OIDC

---

*Voir aussi [`keycloak-setup.md`](keycloak-setup.md) pour la configuration du client OIDC `web-nginx`, et [`architecture.md`](architecture.md) pour la place de SRV-WEB dans le schéma global.*
