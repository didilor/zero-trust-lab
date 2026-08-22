Zero Trust Lab

Lab de sécurité personnel pour la mise en pratique d'une architecture Zero Trust : PKI interne, gestion d'identité centralisée (Keycloak/OIDC), authentification forte (MFA), et reverse proxy authentifiant.

🎯 Objectifs
Mettre en œuvre les principes Zero Trust (vérification systématique, moindre privilège, aucune confiance implicite basée sur le réseau) sur une infrastructure réaliste
Pratiquer l'intégration PKI ↔ AD ↔ IAM (Keycloak) ↔ reverse proxy ↔ client
Faire superviser cette architecture par le SOC (Wazuh) déjà en place sur un lab séparé, en gardant une segmentation réseau stricte
Architecture

<img width="648" height="426" alt="Capture d&#39;écran 2026-08-22 161552" src="https://github.com/user-attachments/assets/da9431c2-a032-40cc-9d8c-5836992bbcdb" />


Schéma détaillé, flux et choix réseau dans docs/architecture.md

🧰 Composants
Composant	Rôle
SRV-PKI	Autorité de certification interne (AD CS)
SRV-AD1	Active Directory, source d'identité
Keycloak	IAM — authentification OIDC + MFA
SRV-WEB	Reverse proxy authentifiant (NGINX + OAuth2 Proxy)
Client Windows 11	Poste utilisateur final
🌐 Infrastructure

Hébergé sur Proxmox, sur le même serveur physique que le SOC home lab, mais sur un bridge réseau totalement isolé. La communication entre les deux labs passe par un point de contrôle unique (OPNsense du SOC) — voir docs/interconnexion-soc.md.

✅ État d'avancement
 Architecture définie (PKI, AD, Keycloak, reverse proxy, client)
 Déploiement SRV-PKI (AD CS) — certificat délivré au contrôleur de domaine
 Déploiement SRV-AD1
 Déploiement et configuration Keycloak (OIDC + MFA)
 Déploiement SRV-WEB (NGINX + OAuth2 Proxy)
 Enrôlement du client Windows 11
 Interconnexion avec le SOC pour supervision Wazuh
🚀 Évolutions (renforcement de l'architecture)

<img width="1538" height="770" alt="Capture d&#39;écran 2026-08-22 162058" src="https://github.com/user-attachments/assets/1a0769fc-7a8d-4ad5-8b9d-6caf7f9adc5a" />


KC01 et KC02 partagent le même état applicatif via PostgreSQL — pas de synchronisation manuelle entre les deux nœuds. Détails et tests de bascule dans docs/ha-setup.md.

 Haute disponibilité Active Directory (SRV-AD02, réplication multi-maîtres, test de bascule validé)
 Haute disponibilité Keycloak (SRV-KC02, base PostgreSQL partagée sur SRV-DB01, test de bascule validé)
 Test de charge sur l'application protégée (k6 — 782 requêtes, 100 % de succès, p95 98,41 ms)
 Squelette Infrastructure as Code (Terraform + Ansible, validé sur SRV-DB01)
 Extension de la PKI interne à Keycloak et NGINX (actuellement en certificats auto-signés)
 Haute disponibilité du reverse proxy (NGINX/OAuth2 Proxy)

Détails techniques dans docs/ha-setup.md et docs/load-testing.md

🔗 Lien avec le SOC

Le SOC (Wazuh) doit superviser les événements de ce lab Zero Trust (authentifications, échecs MFA, anomalies OIDC) sans que les deux réseaux soient fusionnés. Le flux passe par une interface dédiée sur OPNsense, avec des règles de pare-feu restreintes au strict nécessaire (remontée des logs vers Wazuh uniquement).

⚠️ Note

Ce lab est un environnement isolé à usage pédagogique. Les configurations partagées ici sont nettoyées de tout secret ou mot de passe réel — voir .gitignore (certificats/clés PKI, secrets clients OIDC, cookie secret OAuth2 Proxy notamment).
