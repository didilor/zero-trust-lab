# Wazuh Setup — SIEM

## Objectif

Déployer Wazuh comme SIEM central du lab, collectant les logs de l'ensemble des composants (AD, OPNsense, endpoints) pour la détection d'incidents et l'entraînement blue team.

## Informations générales

| Élément | Valeur |
|---|---|
| Version | 4.14.4-1 |
| IP | 192.168.50.40 |
| Rôle réseau | Serveur SIEM central du LAN host-only |

## Composants Wazuh

Wazuh repose sur trois briques principales :
- **Wazuh Manager** : reçoit et analyse les événements, applique les règles de détection
- **Wazuh Indexer** : stocke et indexe les données (basé sur OpenSearch)
- **Wazuh Dashboard** : interface de visualisation

## Installation

Installation réalisée via le script d'installation "all-in-one" officiel (Manager + Indexer + Dashboard sur la même machine), adapté à un contexte lab.

```bash
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
sudo bash wazuh-install.sh -a
```

> Adapter la version dans l'URL selon la release utilisée (ici 4.14.x).

## Sources de logs intégrées

- **Agents Wazuh** installés sur les endpoints du domaine (WIN11, SRV-AD1) pour la collecte d'événements Windows (sécurité, système, PowerShell)
- **Syslog** en provenance d'OPNsense (firewall/IDS Suricata) — voir configuration du forwarding ci-dessous

## Forwarding syslog depuis OPNsense

Configuration côté OPNsense (`System > Settings > Logging / Targets`) pour envoyer les logs vers l'IP de Wazuh (192.168.50.40) sur le port syslog standard.

Points de vigilance :
- Ouvrir le port syslog dans les règles firewall LAN d'OPNsense si nécessaire
- Vérifier côté Wazuh que les decoders correspondants sont actifs pour bien parser les logs pfSense/OPNsense

## Règles de détection

Règles par défaut de Wazuh complétées progressivement pour couvrir les scénarios simulés dans le lab (voir [`../attack-scenarios/`](../attack-scenarios/)) :
- Détection de brute-force SMB (NetExec)
- Détection d'énumération BloodHound / requêtes LDAP suspectes
- Détection de DCSync (répliques anormales du contrôleur de domaine)
- Alertes Pass-the-Hash

## Problèmes rencontrés

Deux problèmes récurrents ont affecté le déploiement — détaillés dans [`troubleshooting.md`](troubleshooting.md) :
- Conflits de heap JVM sur l'indexeur (config `jvm.options` à ajuster selon la RAM de la VM)
- Permissions incorrectes sur `/etc/wazuh-indexer/backup` empêchant le démarrage du service

## Accès

Dashboard accessible via navigateur à l'adresse de la VM Wazuh (HTTPS, port par défaut 443). Identifiants stockés hors dépôt — voir gestion des secrets du lab (`.gitignore`).

---

*Voir aussi [`architecture.md`](architecture.md) pour la place de Wazuh dans le schéma global, et [`ad-setup.md`](ad-setup.md) pour la configuration des agents sur les postes du domaine.*
