# Troubleshooting — SOC Home Lab

Journal des problèmes rencontrés pendant la construction du lab, leur diagnostic et leur résolution.

---

## Wazuh Indexer — conflits de heap JVM

**Symptôme** : l'indexeur Wazuh refuse de démarrer ou crash après quelques minutes.

**Cause** : conflit de configuration de la taille de heap JVM (`-Xms` / `-Xmx`), souvent lié à une valeur mal dimensionnée par rapport à la RAM disponible sur la VM, ou à un fichier `jvm.options` corrompu/dupliqué.

**Résolution** :
- Vérifier `/etc/wazuh-indexer/jvm.options`
- Fixer `-Xms` et `-Xmx` à une valeur identique, ne dépassant pas ~50% de la RAM allouée à la VM
- Redémarrer le service et vérifier les logs (`/var/log/wazuh-indexer/`)

---

## Wazuh Indexer — permissions sur `/etc/wazuh-indexer/backup`

**Symptôme** : échec au démarrage avec des erreurs liées à l'accès au dossier de backup.

**Cause** : permissions incorrectes sur `/etc/wazuh-indexer/backup` (propriétaire/groupe ne correspondant pas à l'utilisateur `wazuh-indexer`).

**Résolution** :
- Corriger le propriétaire du dossier (`chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/backup`)
- Vérifier les droits d'accès (lecture/écriture pour le service)
- Relancer le service et confirmer dans les logs que le dossier est bien pris en compte

---

## OPNsense — configuration Suricata (IDS)

**Symptôme** : Suricata ne détecte pas le trafic attendu ou génère des faux positifs/négatifs.

**Points de vigilance** :
- Bonne interface d'écoute sélectionnée (LAN vs WAN selon ce qu'on veut inspecter)
- Règles activées et à jour (mise à jour des rulesets)
- Mode IDS (détection) vs IPS (blocage actif) bien choisi selon l'objectif du test

---

## Syslog — forwarding vers Wazuh

**Symptôme** : les logs des équipements (OPNsense, AD, endpoints) n'apparaissent pas dans Wazuh.

**Points de vigilance** :
- Vérifier la configuration syslog côté source (adresse IP et port du serveur Wazuh)
- Vérifier que le port syslog est bien ouvert entre la source et Wazuh (règles firewall OPNsense)
- Contrôler le parsing côté Wazuh (decoders/rules) pour confirmer que les logs reçus sont bien interprétés

---

## Migration pfSense → OPNsense

**Cause du changement** : pfSense a basculé une partie de ses fonctionnalités de mise à jour derrière un modèle payant (pfSense Plus), rendant la maintenance gratuite plus contraignante à long terme.

**Résolution** : migration complète vers OPNsense, qui reste 100% open source, avec reconstruction des règles firewall et de la configuration réseau depuis zéro.

---

## Migration réseau NAT → host-only

**Symptôme** : conflits d'adressage et manque de contrôle sur le réseau en mode NAT (`192.168.126.x`).

**Résolution** : passage à un réseau VMware host-only dédié (`192.168.50.0/24`, DHCP VMware désactivé, toutes les IPs en statique) pour le LAN derrière OPNsense. Le réseau NAT (`192.168.126.x`, VMnet8) est conservé uniquement pour fournir l'accès Internet à l'interface WAN d'OPNsense.

---

## 🔴 En cours — LAN ne peut pas joindre Internet via OPNsense

**Symptôme** : OPNsense lui-même joint Internet sans problème (ping `192.168.126.2` et `8.8.8.8` OK depuis le firewall). L'intercommunication complète entre machines du LAN fonctionne. Mais les clients du LAN ne peuvent pas pinger `8.8.8.8` en passant par OPNsense.

**Déjà vérifié** :
- NAT sortant automatique activé
- Règles d'autorisation sur l'interface LAN en place

**Pistes à explorer** :
- Vérifier que la règle NAT sortant correspond bien au bon sous-réseau source (`192.168.50.0/24`)
- Contrôler l'ordre des règles de pare-feu sur l'interface LAN (une règle plus restrictive placée avant pourrait bloquer implicitement)
- Vérifier la table de routage sur les clients LAN (passerelle par défaut = IP LAN d'OPNsense)
- Capturer le trafic sur l'interface WAN d'OPNsense pendant un ping depuis un client LAN pour voir si le paquet sort bien nated
- Vérifier les logs firewall en temps réel (`Firewall > Log Files > Live View`) pour voir si le trafic est droppé et par quelle règle

---

*Ce fichier est mis à jour au fil des sessions de travail sur le lab.*
