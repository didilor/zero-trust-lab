# Interconnexion avec le SOC

## Objectif

Permettre au SOC (Wazuh) de superviser les événements du lab Zero Trust (EYDIE-LAB) — authentifications, échecs MFA, anomalies OIDC — sans fusionner les deux réseaux, qui doivent rester isolés l'un de l'autre par principe.

## Contexte

Les deux labs sont hébergés sur **Proxmox, sur le même serveur physique**, mais sur **deux bridges réseau totalement isolés** :
- Bridge SOC : héberge SRV-AD1, WIN11, Wazuh, TheHive, GLPI, Kali
- Bridge Zero Trust (EYDIE-LAB) : héberge SRV-PKI, SRV-AD1, Keycloak, SRV-WEB, client Windows 11

Aucune communication directe n'existe entre les deux bridges par défaut.

## Principe retenu : OPNsense comme point de jonction unique

Plutôt que de relier directement les deux bridges Proxmox, la communication passe par une **interface supplémentaire ajoutée à la VM OPNsense** du SOC :

```
Bridge SOC (192.168.50.0/24)        Bridge Zero Trust
        │                                    │
        └──────────────► OPNsense ◄──────────┘
                    (interface OPT1 ajoutée)
```

- Sur Proxmox, une interface réseau supplémentaire est ajoutée à la VM OPNsense, reliée au bridge Zero Trust
- Cela crée une 3ᵉ interface (`OPT1`) sur OPNsense, avec ses propres règles de pare-feu, indépendantes de LAN et WAN
- Le lab Zero Trust n'est jamais "dans" le LAN du SOC : il passe par un point de contrôle unique, audité et restreint

## Règles de pare-feu

Seul le flux nécessaire à la supervision est autorisé, dans un seul sens (Zero Trust → SOC) :

| Source | Destination | Port | Objectif |
|---|---|---|---|
| VMs EYDIE-LAB (SRV-AD1, SRV-PKI, Keycloak, SRV-WEB, client) | Wazuh (192.168.50.40) | 1514 (agent Wazuh, TCP/UDP), 514 (syslog) | Remontée des logs/événements vers le SIEM |

Tout le reste (SOC → Zero Trust, Zero Trust → SOC hors Wazuh) reste bloqué par défaut sur l'interface OPT1.

## Supervision côté Wazuh

- **Agent Wazuh** installé sur chaque machine du lab Zero Trust (SRV-AD5, SRV-PKI, SRV-WEB, client Windows 11) plutôt que du syslog seul, pour une collecte plus fiable côté Windows/AD
- **Keycloak** : export des logs applicatifs (authentifications réussies/échouées, échecs MFA, émissions de jetons OIDC) vers l'agent Wazuh local ou en syslog vers Wazuh
- **OAuth2 Proxy / NGINX** : logs d'accès et de refus d'authentification également remontés, utiles pour détecter des tentatives d'accès anormales à la ressource protégée

## Événements à surveiller en priorité

- Échecs d'authentification répétés (bruteforce potentiel sur Keycloak)
- Échecs MFA répétés pour un même compte
- Tentatives d'accès direct à SRV-WEB sans passer par le flux OIDC complet
- Émissions de jetons OIDC en dehors des horaires/patterns habituels
- Erreurs de vérification de certificat TLS (pourrait indiquer une tentative de MITM ou une mauvaise configuration)

## Statut

Interconnexion **planifiée, à mettre en œuvre** — dépend de la stabilisation complète du lab Zero Trust et de l'ajout de l'interface OPT1 côté OPNsense.

## Points de vigilance

- Ne jamais élargir les règles au-delà du strict flux de supervision (pas d'accès administratif SOC → Zero Trust ou inverse)
- Documenter ici toute évolution des règles de pare-feu une fois l'interconnexion mise en œuvre
- Vérifier régulièrement que l'isolation reste effective (pas de règle "any/any" ajoutée par erreur lors d'un dépannage)

---

*Voir aussi [`../soc-home-lab/docs/opnsense-setup.md`](../../soc-home-lab/docs/opnsense-setup.md) pour la configuration OPNsense côté SOC, et [`architecture.md`](architecture.md) pour la vue d'ensemble du lab Zero Trust.*
