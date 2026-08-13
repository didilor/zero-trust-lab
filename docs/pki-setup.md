# PKI Setup — SRV-PKI (AD CS)

## Objectif

Déployer une autorité de certification interne (AD CS) fournissant les certificats nécessaires au fonctionnement chiffré de l'ensemble du lab Zero Trust : Keycloak, SRV-WEB, et potentiellement le client Windows 11.

## Informations générales

| Élément | Valeur |
|---|---|
| Rôle | AD CS (Active Directory Certificate Services) |
| Nom du serveur | SRV-PKI |
| Fonction | Autorité de certification racine du lab |

## Pourquoi une PKI interne

Plutôt que d'utiliser des certificats auto-signés (non vérifiables, à accepter manuellement partout) ou des certificats publics (inutiles/impossibles pour des noms internes), une PKI interne permet :
- Une chaîne de confiance cohérente, distribuée automatiquement aux machines du domaine
- La pratique de la gestion de cycle de vie des certificats (émission, renouvellement, révocation) comme en entreprise
- L'authentification par certificat pour le client, si retenue (voir [`client-setup.md`](client-setup.md))

## Installation du rôle AD CS

Étapes générales (PowerShell, sur Windows Server) :

```powershell
Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools
Install-AdcsCertificationAuthority `
    -CAType StandaloneRootCA `
    -CACommonName "ZeroTrust-Lab-RootCA" `
    -KeyLength 4096 `
    -HashAlgorithmName SHA256 `
    -ValidityPeriod Years `
    -ValidityPeriodUnits 10
```

> Le choix entre CA racine autonome (Standalone) ou intégrée à l'AD (Enterprise CA) dépend de si SRV-PKI est joint ou non au domaine `m21.lab`/AD1 — à trancher selon l'architecture retenue. Une Enterprise CA simplifie la distribution automatique du certificat racine aux machines du domaine via GPO.

## Modèles de certificats (templates)

Si Enterprise CA : créer des modèles dédiés pour chaque usage :
- **Certificat serveur web** (SRV-WEB, Keycloak) : authentification serveur, clé exportable si besoin
- **Certificat client/utilisateur** (poste Windows 11) : authentification client, si l'authentification par certificat est retenue en complément du MFA

## Distribution du certificat racine

- Si Enterprise CA : distribution automatique via GPO à toutes les machines du domaine
- Sinon : export manuel du certificat racine (`.crt` public uniquement) et installation dans le magasin "Autorités de certification racines de confiance" sur chaque machine (SRV-WEB, Keycloak, client)

## Émission des certificats pour les services

- **Keycloak** : certificat serveur pour HTTPS + LDAPS (communication avec SRV-AD1)
- **SRV-WEB (NGINX)** : certificat serveur pour HTTPS côté client
- Renouvellement à anticiper avant expiration — documenter la durée de validité choisie pour chaque certificat émis

## Points de vigilance

- La **clé privée de la CA racine** est l'élément le plus sensible de tout le lab : jamais exportée, jamais versionnée
- Aucune clé privée de service (Keycloak, NGINX) ne doit être commitée dans le repo — seul le certificat public de la CA (`ca-public/*.crt`) peut être partagé sans risque, voir `.gitignore`
- Documenter dans ce fichier toute révocation ou renouvellement effectué, pour garder une trace de la gestion du cycle de vie

---

*Voir aussi [`architecture.md`](architecture.md) pour la place de la PKI dans le schéma global, et [`keycloak-setup.md`](keycloak-setup.md) / [`web-setup.md`](web-setup.md) pour l'utilisation des certificats émis.*
