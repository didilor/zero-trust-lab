# Scénario d'attaque — Énumération BloodHound & DCSync

## Objectif

Cartographier les chemins d'attaque possibles vers les comptes à privilèges élevés du domaine `m21.lab` avec BloodHound, puis exploiter un chemin identifié jusqu'à l'extraction des hashs via une attaque DCSync.

## Infrastructure utilisée

| Composant | Rôle |
|---|---|
| Kali Linux | Poste attaquant (192.168.50.129) |
| BloodHound CE | Cartographie des relations et chemins d'attaque AD |
| SharpHound / bloodhound-python | Collecte des données depuis le domaine |
| Impacket (`secretsdump.py`) | Exécution de l'attaque DCSync |
| SRV-AD1 | Cible — contrôleur de domaine `m21.lab` |
| Wazuh | SIEM — détection des événements générés |

## Déroulé du scénario

### 1. Collecte des données (SharpHound / bloodhound-python)

Collecte des informations du domaine depuis Kali avec des identifiants d'un compte utilisateur standard (illustrant qu'un accès de bas niveau suffit à démarrer l'énumération) :

```bash
bloodhound-python -u <user> -p <password> -d m21.lab -ns 192.168.50.10 -c All
```

### 2. Analyse dans BloodHound

Import des fichiers JSON générés dans l'interface BloodHound CE, puis recherche de chemins d'attaque via les requêtes intégrées :
- **Shortest Paths to Domain Admins** — identification des chemins les plus courts vers les comptes à privilèges élevés
- Analyse des relations `MemberOf`, `AdminTo`, `HasSession`, `GenericAll`/`GenericWrite` exploitables

### 3. Exploitation — DCSync

Une fois un chemin identifié menant à un compte disposant des droits de réplication (`Replicating Directory Changes` / `Replicating Directory Changes All`), exécution de l'attaque DCSync avec Impacket :

```bash
secretsdump.py m21.lab/<compte-compromis>:<password>@192.168.50.10
```

Cette attaque simule le comportement d'un contrôleur de domaine légitime demandant une réplication, permettant d'extraire les hashs NTLM de tous les comptes du domaine, y compris les comptes à privilèges élevés.

## Résultats obtenus

- Chemin d'attaque complet identifié et cartographié dans BloodHound, du compte utilisateur de départ jusqu'aux droits de réplication
- Extraction réussie des hashs via DCSync

## Détection côté Wazuh

Événements à surveiller pour détecter ce type d'attaque :
- **Event ID 4662** (Windows Security) — accès à un objet avec les GUID correspondant aux droits de réplication (`Replicating Directory Changes`), un signal fort de tentative de DCSync
- **Event ID 4624/4625** — connexions LDAP anormales en provenance d'une machine qui n'est pas un contrôleur de domaine légitime
- Volume inhabituel de requêtes LDAP en provenance d'un même hôte (signature de la collecte SharpHound/BloodHound)

## Enseignements

- L'attaque DCSync ne nécessite pas d'accès administrateur direct : un chemin de droits mal configuré (délégation excessive, appartenance à un groupe avec droits de réplication) suffit
- BloodHound illustre concrètement la valeur du principe de moindre privilège : plus les relations `AdminTo`/`GenericAll` sont nombreuses et mal maîtrisées, plus les chemins d'attaque se multiplient
- La détection Wazuh basée sur l'Event ID 4662 est la ligne de défense la plus fiable contre ce type de technique, plus efficace qu'une détection basée uniquement sur le volume de requêtes LDAP

## Points de vigilance

- Aucun hash extrait (même en lab) ne doit être versionné dans le repo — voir `.gitignore` (`*.kirbi`, `*.ccache`, `hashes.txt`, `loot/`)
- Les fichiers JSON générés par BloodHound peuvent contenir des noms de comptes réels du lab — à exclure ou anonymiser avant tout partage public

---

*Voir aussi [`pth-netexec.md`](pth-netexec.md) pour la suite du scénario (mouvement latéral avec les hashs obtenus), et [`../docs/wazuh-setup.md`](../docs/wazuh-setup.md) pour la configuration générale du SIEM.*
