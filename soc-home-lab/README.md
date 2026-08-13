# SOC Home Lab — m21.lab

Lab de sécurité personnel pour la mise en pratique d'architectures SOC : Active Directory, SIEM, firewall nouvelle génération, gestion de parc, et scénarios d'attaque/défense.

## 🎯 Objectifs

- Reproduire une infrastructure d'entreprise réaliste pour l'entraînement en détection et réponse à incident
- Pratiquer des scénarios d'attaque offensifs (red team) et leur détection côté défense (blue team)
- Monter en compétences sur des outils SOC réels : SIEM, EDR, gestion de parc, firewall

## 🏗️ Architecture

Réseau host-only VMware (`192.168.50.0/24`) derrière un firewall OPNsense faisant office de passerelle vers Internet (NAT).

| Composant | Rôle | IP |
|---|---|---|
| OPNsense | Firewall / IDS (Suricata) | Gateway |
| SRV-AD1 | Contrôleur de domaine (`m21.lab`) | 192.168.50.10 |
| WIN11 | Poste client Windows | 192.168.50.30 |
| Wazuh | SIEM (v4.14.4-1) | 192.168.50.40 |
| TheHive | Gestion d'incidents | 192.168.50.60 |
| Kali Linux | Poste attaquant | 192.168.50.129 |
| GLPI | Gestion de parc (Docker) | Port 8080 |

> Schéma détaillé et choix réseau dans [`docs/architecture.md`](docs/architecture.md)

## 🧰 Stack technique

- **Virtualisation** : VMware Workstation
- **Annuaire** : Active Directory (Windows Server), domaine `m21.lab`, 17 OU, 38 utilisateurs
- **SIEM** : Wazuh
- **Firewall/IDS** : OPNsense + Suricata (migration depuis pfSense, abandonné pour cause de mises à jour payantes)
- **ITSM** : GLPI 11 avec intégration AD complète + chatbot helpdesk custom (HTML/JS, API REST GLPI)
- **Attaque** : Kali Linux, Nmap, NetExec, BloodHound CE, Impacket, GoPhish

## ✅ État d'avancement

- [x] Déploiement AD (domaine, OU, utilisateurs)
- [x] Intégration GLPI ↔ AD
- [x] Chatbot helpdesk GLPI (9 étapes, API REST)
- [x] Migration pfSense → OPNsense
- [x] Campagne de phishing complète (GoPhish + Postfix/Dovecot) : envoi, ouverture, clic, capture de credentials
- [x] Scénarios d'attaque : brute-force SMB, BloodHound, DCSync, Pass-the-Hash
- [ ] Résolution du routing LAN → Internet via OPNsense (NAT sortant en cours de debug)
- [ ] Migration vers serveur physique (Dell PowerEdge R430)

## 🐛 Problèmes rencontrés et résolus

Voir [`docs/troubleshooting.md`](docs/troubleshooting.md) — notamment les conflits de heap JVM sur l'indexeur Wazuh et les permissions sur les sauvegardes.

## ⚔️ Scénarios d'attaque/défense

Voir le dossier [`attack-scenarios/`](attack-scenarios/) pour le détail des simulations menées (BloodHound/DCSync, Pass-the-Hash, campagne GoPhish) et leur détection côté Wazuh.

## 🚀 Roadmap

Migration progressive du lab vers un serveur bare metal (Dell PowerEdge R430, RAID5) afin d'héberger l'ensemble des VMs (OPNsense, AD, Wazuh, TheHive, Keycloak) de façon plus stable qu'en environnement virtualisé sur poste personnel.

## ⚠️ Note

Ce lab est un environnement **isolé à usage pédagogique**. Les configurations partagées ici sont nettoyées de tout secret ou mot de passe réel — voir `.gitignore` et les placeholders utilisés dans la documentation.
