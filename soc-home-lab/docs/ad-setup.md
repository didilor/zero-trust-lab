# Active Directory Setup — SRV-AD1

## Objectif

Déployer un contrôleur de domaine Active Directory servant de socle d'identité pour le lab, avec une structure d'OU et d'utilisateurs réaliste pour les scénarios d'attaque/défense et l'intégration avec GLPI.

## Informations générales

| Élément | Valeur |
|---|---|
| Nom du serveur | SRV-AD1 |
| Domaine | `m21.lab` |
| IP | 192.168.50.10 |
| Rôles | Contrôleur de domaine, DNS |

> Un ancien domaine `eydie.lab` avait été utilisé en premier lieu puis abandonné au profit de `m21.lab`, devenu le domaine principal du lab.

## Structure de l'annuaire

- **17 unités d'organisation (OU)** structurant les objets du domaine
- **38 utilisateurs** répartis dans ces OU
- Structure pensée pour refléter une organisation type (services, rôles), utile pour tester des scénarios d'énumération (BloodHound) et de mouvement latéral réalistes

## Installation du rôle AD DS

Étapes générales (PowerShell, sur Windows Server) :

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName "m21.lab" -DomainNetbiosName "M21"
```

Le serveur redémarre et devient contrôleur du nouveau domaine, avec le rôle DNS installé et configuré automatiquement pour la zone du domaine.

## Intégration avec les autres composants

- **WIN11** (192.168.50.30) joint au domaine `m21.lab` comme poste client standard
- **GLPI** intégré à l'AD via un compte de service dédié `svc-glpi@m21.lab`, permettant la synchronisation des utilisateurs (voir [`glpi-setup.md`](glpi-setup.md))
- **Wazuh** collecte les événements de sécurité Windows du contrôleur de domaine via agent (voir [`wazuh-setup.md`](wazuh-setup.md))

## Exposition aux scénarios offensifs

Ce domaine sert de cible principale pour les simulations menées depuis Kali (voir [`../attack-scenarios/`](../attack-scenarios/)) :
- Énumération et cartographie via **BloodHound CE**
- Brute-force SMB via **NetExec**
- Extraction de hashs via **DCSync** (impacket)
- Attaques **Pass-the-Hash**

La richesse de la structure d'OU/utilisateurs permet des chemins d'attaque BloodHound plus représentatifs d'un environnement réel qu'un domaine minimal à quelques comptes.

## Points de vigilance

- Le compte de service `svc-glpi@m21.lab` doit avoir des droits limités au strict nécessaire pour la synchronisation LDAP — à ne pas sur-privilégier, même en lab, pour que les scénarios de compromission restent pertinents pédagogiquement
- Aucun mot de passe ou export d'annuaire (`ntds.dit`, ruches SAM/SECURITY) ne doit être versionné — voir `.gitignore`

---

*Voir aussi [`architecture.md`](architecture.md) pour la place du contrôleur de domaine dans le schéma réseau global.*
