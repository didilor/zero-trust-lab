# Scénario d'attaque — Campagne de phishing (GoPhish)

## Objectif

Simuler une campagne de phishing complète, de l'envoi de l'email jusqu'à la capture de credentials, puis vérifier la détection côté SOC via la remontée des logs vers Wazuh.

## Infrastructure utilisée

| Composant | Rôle |
|---|---|
| GoPhish | Plateforme de simulation de phishing (création de campagne, tracking) |
| Postfix | Serveur SMTP pour l'envoi des emails de phishing |
| Dovecot | Serveur IMAP, réception côté "victime" |
| Thunderbird | Client mail utilisé côté poste victime pour lire les emails reçus |
| Wazuh | SIEM — collecte des logs générés par le scénario |

## Déroulé du scénario

1. **Préparation** : création d'une campagne GoPhish avec un modèle d'email de phishing et une page de destination imitant un formulaire de connexion
2. **Envoi** : les emails sont envoyés via l'infrastructure Postfix/Dovecot configurée pour le lab
3. **Réception côté victime** : les emails sont consultés dans **Thunderbird**, configuré sur le poste victime pour se connecter à la boîte mail via Dovecot (IMAP)
4. **Interaction** : ouverture de l'email, clic sur le lien de phishing
5. **Capture** : saisie de credentials sur la fausse page de connexion, capturés par GoPhish

## Résultats obtenus

Le scénario a été mené jusqu'au bout avec un suivi complet dans le tableau de bord GoPhish :
- ✅ Email envoyé
- ✅ Email ouvert
- ✅ Lien cliqué
- ✅ Credentials soumis/capturés

## Remontée des logs vers Wazuh

Les événements générés par le scénario (réception mail, activité Thunderbird, tentative de connexion) ont été remontés vers Wazuh, permettant de vérifier la chaîne de détection côté SOC — pas seulement l'exécution de l'attaque, mais sa visibilité pour l'équipe défensive.

**Pistes de détection exploitées côté Wazuh** (à détailler/affiner selon les règles réellement configurées) :
- Logs de connexion IMAP (Dovecot) consultables pour repérer un accès inhabituel
- Activité du client Thunderbird sur le poste victime
- Corrélation possible avec les logs SMTP (Postfix) pour retracer l'origine de l'email

## Enseignements

- Ce scénario complète les autres tests offensifs du lab (NetExec, BloodHound, DCSync, Pass-the-Hash — voir les autres fichiers de ce dossier) en couvrant le vecteur d'ingénierie sociale, souvent le point d'entrée initial dans une compromission réelle
- La boucle complète "attaque simulée → log généré → remontée SIEM" est la partie la plus formatrice de l'exercice : elle valide que l'infrastructure de détection du lab fonctionne de bout en bout, pas seulement l'infrastructure offensive

## Points de vigilance

- Aucun credential réel (même de test) capturé pendant la campagne ne doit être versionné dans le repo — voir `.gitignore` (`gophish-results/`, `hashes.txt`, `loot/`)
- Les templates d'emails de phishing utilisés peuvent être partagés à titre pédagogique, mais à vérifier qu'ils ne contiennent aucune donnée sensible avant publication

---

*Voir aussi [`../docs/wazuh-setup.md`](../docs/wazuh-setup.md) pour la configuration générale du SIEM, et [`../docs/troubleshooting.md`](../docs/troubleshooting.md) pour les problèmes de forwarding de logs rencontrés.*
