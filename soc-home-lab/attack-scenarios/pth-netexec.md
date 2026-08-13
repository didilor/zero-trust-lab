# Scénario d'attaque — Brute-force SMB (NetExec) & Pass-the-Hash

## Objectif

Réaliser une attaque de brute-force sur le service SMB pour obtenir des identifiants valides, puis exploiter les hashs récupérés (via le scénario DCSync) avec une attaque Pass-the-Hash pour se déplacer latéralement sur le domaine sans connaître le mot de passe en clair.

## Infrastructure utilisée

| Composant | Rôle |
|---|---|
| Kali Linux | Poste attaquant (192.168.50.129) |
| NetExec (anciennement CrackMapExec) | Brute-force SMB, exécution Pass-the-Hash |
| SRV-AD1 / WIN11 | Cibles du domaine `m21.lab` |
| Wazuh | SIEM — détection des événements générés |

## Déroulé du scénario

### 1. Brute-force SMB avec NetExec

Tentative d'authentification SMB avec une liste d'utilisateurs et de mots de passe courants :

```bash
netexec smb 192.168.50.0/24 -u users.txt -p passwords.txt
```

Objectif : identifier des comptes valides et des combinaisons identifiant/mot de passe fonctionnelles sur les machines du domaine.

### 2. Pass-the-Hash

Une fois un hash NTLM obtenu (par brute-force ou via l'attaque DCSync du scénario [`bloodhound-dcsync.md`](bloodhound-dcsync.md)), authentification directe sur les machines cibles sans connaître le mot de passe en clair :

```bash
netexec smb 192.168.50.0/24 -u <utilisateur> -H <hash-ntlm>
```

Cette technique exploite le fait que le protocole d'authentification NTLM accepte le hash directement, sans nécessiter le mot de passe original.

### 3. Vérification de l'accès obtenu

Une fois l'authentification réussie, vérification des droits obtenus sur les machines cibles (exécution de commandes, accès aux partages SMB) pour confirmer la portée du mouvement latéral possible.

## Résultats obtenus

- Brute-force SMB : identification de combinaisons identifiant/mot de passe valides
- Pass-the-Hash : authentification réussie sur les machines du domaine en utilisant uniquement le hash NTLM, sans mot de passe en clair

## Détection côté Wazuh

Événements à surveiller pour détecter ce type d'attaque :
- **Event ID 4625** (échecs de connexion) en volume important et rapproché depuis une même source — signature du brute-force
- **Event ID 4624** avec **Logon Type 3** (réseau) et **Package Name NTLM** — signal pour une authentification Pass-the-Hash, notamment lorsqu'elle provient d'une machine inhabituelle pour le compte concerné
- Corrélation entre plusieurs échecs de connexion (4625) suivis d'un succès (4624) sur la même source en peu de temps

## Enseignements

- Le brute-force SMB reste efficace dans un environnement sans politique de verrouillage de compte (account lockout policy) — un point à vérifier/durcir dans la configuration AD du lab
- Le Pass-the-Hash illustre pourquoi la rotation régulière des mots de passe seule ne suffit pas : tant qu'un hash reste valide, il permet l'accès, indépendamment de la complexité du mot de passe d'origine
- Ce scénario s'enchaîne naturellement avec le DCSync : DCSync fournit les hashs, Pass-the-Hash les exploite pour le mouvement latéral

## Points de vigilance

- Aucun hash NTLM ni aucune liste de mots de passe utilisée pour le brute-force ne doit être versionné dans le repo — voir `.gitignore` (`hashes.txt`, `loot/`)
- Ne pas publier les listes `users.txt`/`passwords.txt` si elles contiennent des identifiants réels du lab

---

*Voir aussi [`bloodhound-dcsync.md`](bloodhound-dcsync.md) pour l'obtention des hashs exploités ici, et [`../docs/wazuh-setup.md`](../docs/wazuh-setup.md) pour la configuration générale du SIEM.*
