Haute disponibilité — Active Directory & Keycloak

Ce document décrit la mise en œuvre de la haute disponibilité sur les deux composants d'authentification du lab (Active Directory et Keycloak), ajoutée après le déploiement initial pour supprimer les points de défaillance uniques identifiés lors du bilan du lab de base.

Contexte

Le lab initial reposait sur une seule instance de chaque composant : SRV-AD01 (contrôleur de domaine) et SRV-KC01 (Keycloak, base de données locale embarquée). La panne de l'un ou l'autre interrompait tout le parcours d'authentification.

Trois machines ont été ajoutées :

Machine	Rôle	IP
SRV-AD02	2e contrôleur de domaine (réplication multi-maîtres)	192.168.226.52
SRV-KC02	2e nœud Keycloak (cluster, base partagée)	192.168.226.22
SRV-DB01	Base PostgreSQL partagée (état Keycloak)	192.168.226.23
Haute disponibilité Active Directory
Déploiement de SRV-AD02

SRV-AD02 a été installée à partir d'une installation propre de Windows Server 2025 — pas de clonage, déconseillé pour un contrôleur de domaine. La machine a été jointe au domaine en tant que serveur membre, puis promue en contrôleur de domaine additionnel via l'assistant AD DS, avec le service DNS activé sur ce second nœud.

Spécifications : 4096 Mo RAM, 2 vCPU, disque 60 Go.

Validation de la réplication
repadmin /showrepl
Get-ADDomainController -Filter *

Les deux contrôleurs de domaine apparaissent dans le domaine, sans erreur de réplication (dcdiag global réussi, un avertissement mineur résiduel sur l'enregistrement gc._msdcs, non bloquant).

Test de bascule

SRV-AD01 a été arrêté volontairement. Depuis SRV-AD02 :

Get-ADUser -Filter *

La commande a retourné l'ensemble des comptes utilisateurs sans erreur, confirmant que l'annuaire reste interrogeable malgré l'indisponibilité du contrôleur de domaine principal. SRV-AD01 a ensuite été redémarré, la resynchronisation de la réplication a été confirmée.

Haute disponibilité Keycloak
Principe : base de données partagée

Par défaut, chaque instance Keycloak utilise une base de données locale. Cloner une VM Keycloak ne suffit donc pas — chaque nœud évoluerait de manière indépendante après la copie. La solution retenue externalise la base sur une machine dédiée (SRV-DB01, PostgreSQL), à laquelle les deux nœuds Keycloak se connectent.

Mise en place de SRV-DB01

SRV-DB01 a été provisionnée par clonage d'une VM Ubuntu Server existante, puis reconfigurée (machine-id, hostname, IP) avant l'installation de PostgreSQL. Une base keycloak et un utilisateur dédié ont été créés, avec un accès restreint aux seules adresses de SRV-KC01 et SRV-KC02 :

host    keycloak    keycloak    192.168.226.21/32    scram-sha-256
host    keycloak    keycloak    192.168.226.22/32    scram-sha-256
Bascule de SRV-KC01 vers PostgreSQL

Avant toute modification, le realm applicatif a été exporté par précaution. La connexion à PostgreSQL a ensuite été renseignée dans la configuration Keycloak :

db=postgres
db-url=jdbc:postgresql://192.168.226.23:5432/keycloak
db-username=keycloak
db-password=********

La synchronisation avec Active Directory (fédération LDAP) a été relancée depuis la console d'administration, restaurant l'accès à l'ensemble des comptes.

Keycloak n'est pas configuré en service systemd sur ce lab — démarrage manuel via sudo /opt/keycloak/bin/kc.sh start --hostname-strict=false (le sudo est nécessaire, sinon erreur de permissions sur le rebuild Quarkus). C'est une amélioration identifiée pour la suite.

Déploiement de SRV-KC02

SRV-KC02 a été obtenue par clonage complet de SRV-KC01. Après les ajustements post-clonage classiques (machine-id, hostname, IP), SRV-KC02 a été configurée avec la même connexion PostgreSQL que SRV-KC01. Dès le premier démarrage, l'interface d'administration a affiché directement le même realm et les mêmes utilisateurs, sans réimport ni resynchronisation — preuve que les deux nœuds partagent le même état applicatif en temps réel.

Test de bascule

SRV-KC01 a été arrêté volontairement (connexion refusée sur son adresse). SRV-KC02 est resté pleinement fonctionnel, avec le même realm et les mêmes comptes. SRV-KC01 a ensuite été redémarré, confirmant le retour à un cluster à deux nœuds opérationnels.

Point d'attention résolu

Après la bascule PostgreSQL, les comptes synchronisés depuis Active Directory sont apparus temporairement avec l'indicateur « email non vérifié » dans Keycloak, faute d'un mapper LDAP dédié à cet attribut. Corrigé par l'ajout d'un mapper LDAP hardcoded-attribute-mapper (emailVerified=true), sans impact sur le parcours d'authentification ni sur le second facteur (MFA/OTP).

Limites restantes
Le serveur Web (NGINX/OAuth2 Proxy) reste un point de défaillance unique — pas de redondance à ce stade.
La PKI interne (SRV-PKI) délivre un certificat au contrôleur de domaine, mais Keycloak et NGINX utilisent des certificats auto-signés, sans intégration à la PKI.
Keycloak n'est pas géré en service systemd — démarrage manuel requis après un redémarrage de VM.
