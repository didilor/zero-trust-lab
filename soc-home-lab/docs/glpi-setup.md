# GLPI Setup — ITSM

## Objectif

Déployer GLPI comme outil de gestion de parc et de helpdesk, intégré à l'Active Directory du lab, avec un chatbot custom pour automatiser une partie du support niveau 1.

## Informations générales

| Élément | Valeur |
|---|---|
| Version | GLPI 11 |
| Déploiement | Docker |
| Port | 8080 |
| Intégration AD | Complète (domaine `m21.lab`) |

## Déploiement

GLPI est déployé via Docker, ce qui simplifie l'installation et l'isolation du service par rapport au reste du système hôte.

```bash
docker run -d --name glpi \
  -p 8080:80 \
  -v glpi_data:/var/www/html/glpi \
  -e TIMEZONE="Europe/Paris" \
  diouxx/glpi
```

> Adapter l'image Docker et les variables d'environnement selon la configuration réellement utilisée.

## Intégration Active Directory

Synchronisation LDAP configurée avec le domaine `m21.lab` :
- Compte de service dédié : `svc-glpi@m21.lab`
- Import automatique des 38 utilisateurs et de la structure des 17 OU depuis l'AD (voir [`ad-setup.md`](ad-setup.md))
- Le compte de service dispose uniquement des droits nécessaires à la lecture LDAP (pas de droits d'administration du domaine)

Configuration côté GLPI : `Configuration > Authentification > Annuaires LDAP`, avec le DN du compte de service, le filtre de recherche adapté aux OU, et la base DN correspondant à `DC=m21,DC=lab`.

## Chatbot helpdesk

Un chatbot custom en **HTML/JavaScript** a été développé pour automatiser une partie du parcours de création de ticket, en s'appuyant sur l'**API REST de GLPI**.

**Fonctionnement en 9 étapes** :
1. Accueil et identification de l'utilisateur
2. Choix de la catégorie du problème
3. Description guidée du problème
4. Collecte des informations complémentaires (équipement concerné, urgence, etc.)
5. Récapitulatif avant soumission
6. Création du ticket via l'API GLPI (`POST /apirest.php/Ticket`)
7. Confirmation et numéro de ticket
8. Proposition de suivi ou de nouvelle demande
9. Fin de session / retour à l'accueil

L'API REST GLPI nécessite un jeton d'application (App Token) et une authentification par jeton utilisateur ou session — ces éléments ne doivent pas être codés en dur dans le JavaScript côté client en dehors du contexte lab (voir points de vigilance).

## Points de vigilance

- Les tokens API GLPI (App Token, User Token) ne doivent jamais être versionnés en clair — à externaliser dans une configuration non commitée (voir `.gitignore`)
- Le compte de service AD utilisé par GLPI doit rester à privilèges minimaux
- Le code du chatbot est un bon candidat pour un sous-dossier dédié du repo (`scripts/glpi-chatbot/`) avec son propre README expliquant comment le reconfigurer pour une autre instance GLPI

---

*Voir aussi [`architecture.md`](architecture.md) pour la place de GLPI dans le schéma global, et [`ad-setup.md`](ad-setup.md) pour la structure de l'annuaire synchronisé.*
