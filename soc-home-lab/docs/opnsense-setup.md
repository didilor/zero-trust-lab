# OPNsense Setup — Firewall / IDS

## Objectif

Déployer OPNsense comme firewall périmétrique du lab, assurant la séparation entre le LAN interne et Internet, avec inspection du trafic via Suricata (IDS).

## Informations générales

| Élément | Valeur |
|---|---|
| WAN | VMnet8 (NAT), 192.168.126.x, gateway 192.168.126.2 |
| LAN | VMnet1 (host-only), 192.168.50.1/24 |
| IDS | Suricata |

## Pourquoi OPNsense plutôt que pfSense

pfSense a basculé une partie de ses fonctionnalités de mise à jour derrière un modèle payant (pfSense Plus). OPNsense reste 100% open source, ce qui en fait un choix plus pérenne pour un lab personnel maintenu sur la durée. La migration a nécessité une reconstruction complète des règles firewall et de la configuration réseau depuis zéro.

## Interfaces réseau

- **WAN** : rattachée à VMnet8 (NAT VMware), fournit l'accès Internet
- **LAN** : rattachée à VMnet1 (host-only), DHCP VMware désactivé — toutes les machines du LAN ont une IP statique

Ce découpage isole complètement le LAN du réseau de l'hôte physique ; seul OPNsense fait la jonction.

## Règles de pare-feu

Configuration de base :
- **LAN → any** : autorisé (NAT sortant automatique) pour permettre aux machines du LAN de sortir vers Internet via OPNsense
- **WAN → LAN** : bloqué par défaut, sauf règles explicites si besoin de services exposés (non utilisé actuellement dans le lab)

## Suricata (IDS)

Suricata est activé pour l'inspection du trafic, avec :
- Interface d'écoute à définir selon l'objectif (LAN pour observer le trafic interne, WAN pour le trafic sortant/entrant)
- Rulesets tenus à jour
- Mode IDS (détection, sans blocage actif) privilégié pour ne pas perturber les scénarios de test tout en générant des alertes exploitables dans Wazuh

## Forwarding des logs vers Wazuh

OPNsense envoie ses logs (firewall + Suricata) en syslog vers Wazuh (192.168.50.40). Voir [`wazuh-setup.md`](wazuh-setup.md) pour la configuration côté SIEM.

## Problème en cours : LAN sans accès Internet via OPNsense

**Statut : non résolu**

OPNsense lui-même accède à Internet sans problème, et l'intercommunication entre machines du LAN fonctionne. Mais les clients du LAN ne parviennent pas à joindre Internet en passant par OPNsense, malgré le NAT sortant automatique activé et les règles d'autorisation LAN en place.

Diagnostic en cours — voir le détail des pistes explorées dans [`troubleshooting.md`](troubleshooting.md).

## Points de vigilance

- Ne pas versionner les exports de configuration bruts d'OPNsense (`config.xml`) sans les avoir nettoyés de tout secret (mots de passe, clés VPN éventuelles) — voir `.gitignore`
- Documenter tout changement de règle firewall ici pour garder une trace de l'évolution de la politique de sécurité du lab

---

*Voir aussi [`architecture.md`](architecture.md) pour la place d'OPNsense dans le schéma réseau global.*
