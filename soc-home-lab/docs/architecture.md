# Architecture — SOC Home Lab (m21.lab)

## Vue d'ensemble

Le lab simule une infrastructure d'entreprise classique : un LAN interne protégé par un firewall périmétrique, avec un annuaire Active Directory, un SIEM pour la détection, un outil ITSM pour la gestion de parc, et un poste attaquant isolé pour les scénarios offensifs.

```
                         Internet
                            │
                            │
                     ┌──────┴──────┐
                     │   OPNsense  │  WAN: 192.168.126.x (NAT/VMnet8)
                     │  Firewall/  │  LAN: 192.168.50.1 (VMnet1 host-only)
                     │  IDS        │
                     └──────┬──────┘
                            │
              ┌─────────────┼─────────────┬──────────────┬─────────────┐
              │             │             │              │             │
        192.168.50.10 192.168.50.30 192.168.50.40  192.168.50.60 192.168.50.129
         ┌────┴────┐   ┌────┴────┐   ┌────┴────┐   ┌────┴────┐  ┌────┴────┐
         │ SRV-AD1 │   │  WIN11  │   │  Wazuh  │   │ TheHive │  │  Kali   │
         │   DC    │   │ Client  │   │  SIEM   │   │  IR     │  │ Attaquant│
         │ m21.lab │   │         │   │         │   │         │  │         │
         └─────────┘   └─────────┘   └─────────┘   └─────────┘  └─────────┘
                                          │
                                     ┌────┴────┐
                                     │  GLPI   │  (Docker, port 8080)
                                     │  ITSM   │
                                     └─────────┘
```

## Segmentation réseau

Deux réseaux virtuels VMware distincts :

| Réseau | Type | Plage | Rôle |
|---|---|---|---|
| VMnet1 | Host-only | 192.168.50.0/24 | LAN interne, derrière OPNsense. DHCP VMware désactivé — toutes les IPs sont statiques. |
| VMnet8 | NAT | 192.168.126.0/24 | Fournit l'accès Internet à l'interface WAN d'OPNsense (gateway 192.168.126.2). |

Ce choix isole complètement le LAN du reste du réseau hôte : seul OPNsense fait la jonction entre les deux, ce qui permet de contrôler et d'inspecter tout le trafic sortant/entrant comme dans une vraie architecture d'entreprise.

## Composants et adressage

| Composant | Fonction | IP | Détails |
|---|---|---|---|
| OPNsense | Firewall / IDS | Gateway LAN + WAN 192.168.126.x | Suricata activé pour l'inspection du trafic |
| SRV-AD1 | Contrôleur de domaine | 192.168.50.10 | Windows Server, domaine `m21.lab`, fait aussi office de DNS, 17 OU / 38 utilisateurs |
| WIN11 | Poste client | 192.168.50.30 | Joint au domaine, cible/point d'observation pour les scénarios d'attaque |
| Wazuh | SIEM | 192.168.50.40 | Version 4.14.4-1, centralise les logs (syslog, agents) |
| TheHive | Gestion d'incidents | 192.168.50.60 | Réponse à incident, suivi des cas |
| Kali Linux | Poste attaquant | 192.168.50.129 | Nmap, NetExec, BloodHound, Impacket, GoPhish |
| GLPI | ITSM | Port 8080 (Docker) | Intégré à l'AD, chatbot helpdesk custom |

## Choix de conception

**Pourquoi OPNsense plutôt que pfSense**
pfSense a basculé une partie de ses mises à jour derrière un modèle payant (pfSense Plus). OPNsense reste 100% open source, ce qui correspond mieux à l'usage lab/apprentissage sur le long terme.

**Pourquoi host-only plutôt que NAT pour le LAN**
Le mode NAT (utilisé initialement, 192.168.126.x) ne permettait pas un contrôle fin du plan d'adressage ni une segmentation propre. Le passage en host-only avec IPs statiques donne une topologie stable et reproductible, plus proche d'un environnement d'entreprise réel.

**Pourquoi séparer TheHive de Wazuh**
Wazuh assure la détection (SIEM), TheHive prend le relais pour la gestion de la réponse à incident — une séparation qui reflète la chaîne de valeur SOC détection → qualification → réponse.

## Évolution prévue

Migration progressive du lab vers un serveur bare metal (Dell PowerEdge R430, contrôleur RAID PERC H330 Mini, RAID5 ~836 Go, iDRAC en 192.168.0.120) pour héberger l'ensemble des VMs (OPNsense, AD, Windows 11, Kali, Wazuh, TheHive, et à terme Keycloak) de façon plus stable et performante qu'en virtualisation sur poste personnel. Le serveur ne sera allumé que pendant les sessions de travail actives, pour limiter la consommation électrique.

---

*Schéma et adressage à jour au [date de dernière session lab]. Voir [`troubleshooting.md`](troubleshooting.md) pour les problèmes réseau en cours.*
