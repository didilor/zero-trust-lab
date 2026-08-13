# Client Setup — Poste Windows 11

## Objectif

Le poste Windows 11 est le point de départ du parcours utilisateur Zero Trust d'EYDIE-LAB : il initie la requête HTTPS vers SRV-WEB, est redirigé vers Keycloak pour authentification, et n'obtient l'accès à la ressource protégée qu'une fois l'identité vérifiée (LDAP + MFA).

## Informations générales

| Élément | Valeur |
|---|---|
| OS | Windows 11 |
| Rôle | Poste utilisateur final |
| Ressource cible | Page protégée sur SRV-WEB (`https://192.168.226.142`) |

## Parcours d'authentification depuis le client

1. L'utilisateur accède à `https://192.168.226.142` depuis un navigateur sur le poste Windows 11
2. NGINX (via `auth_request`) détecte l'absence de session valide → redirection vers `/oauth2/sign_in`
3. OAuth2 Proxy redirige vers Keycloak pour authentification
4. Keycloak authentifie l'utilisateur via LDAP (SRV-AD1) puis demande le second facteur (MFA/OTP)
5. Après validation, Keycloak redirige vers l'URL de callback OAuth2 Proxy (`/oauth2/callback`)
6. OAuth2 Proxy établit une session et redirige vers NGINX
7. NGINX sert la page protégée d'EYDIE-LAB

Ce parcours complet a été testé et validé de bout en bout (voir [`web-setup.md`](web-setup.md)).

## Confiance TLS côté client

Pour que le navigateur du poste Windows 11 fasse confiance aux certificats HTTPS émis par SRV-PKI (Keycloak, SRV-WEB) sans avertissement de sécurité :
- Installer le certificat racine de SRV-PKI dans le magasin **"Autorités de certification racines de confiance"** du poste
- Si SRV-AD1/SRV-PKI sont en Enterprise CA et le poste joint au domaine : distribution automatique possible via GPO
- Sinon : import manuel du certificat public de la CA (`.crt`), voir [`pki-setup.md`](pki-setup.md)

## Authentification par certificat (optionnel, à trancher)

Selon le choix retenu dans [`pki-setup.md`](pki-setup.md), le poste peut également être équipé d'un certificat client/machine émis par SRV-PKI, pour renforcer l'authentification en amont ou en complément de l'authentification Keycloak. Ce point reste à définir précisément (authentification par certificat only, en complément du MFA, ou non utilisée dans cette itération du lab).

## Points de vigilance

- Vérifier la résolution DNS ou l'entrée `hosts` locale du poste pour joindre SRV-WEB et Keycloak par leur nom/IP correcte
- En cas d'IP changeante (DHCP côté lab), les URLs de callback codées en dur côté OAuth2 Proxy/Keycloak devront être mises à jour en conséquence
- Ne pas versionner de capture d'écran ou d'export contenant des cookies de session ou des jetons OIDC valides

---

*Voir aussi [`web-setup.md`](web-setup.md) pour le détail du parcours côté serveur, [`keycloak-setup.md`](keycloak-setup.md) pour le MFA, et [`pki-setup.md`](pki-setup.md) pour la distribution du certificat racine.*
