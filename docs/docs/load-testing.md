Test de charge — k6

Test de charge réalisé sur l'application protégée du lab afin de valider la robustesse de l'architecture sous sollicitation.

Outil et méthode

Outil : k6, installé via sudo snap install k6 sur SRV-DB01 (l'installation via dépôt apt a échoué).

Le test simule 15 utilisateurs virtuels adressant des requêtes en continu pendant 30 secondes vers le point d'entrée de l'application (SRV-WEB01), chaque requête étant vérifiée sur son code de statut HTTP.

javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 15,
  duration: '30s',
  insecureSkipTLSVerify: true,
};

export default function () {
  const res = http.get('https://192.168.226.142/');
  check(res, { 'status is 200 or 302': (r) => [200, 302].includes(r.status) });
  sleep(1);
}
Résultats
Indicateur	Résultat
Requêtes totales	782
Taux de succès	100 % (0 échec)
Temps de réponse moyen	77,78 ms
Temps de réponse p95	98,41 ms
Débit soutenu	≈ 25,3 requêtes/seconde

L'ensemble des requêtes a abouti sans erreur, avec un temps de réponse constamment inférieur à 100 ms pour 95 % des requêtes.

Limites du test

Ce test reste modeste au regard d'un environnement de production réel : nombre d'utilisateurs virtuels limité, durée courte, un seul point d'entrée testé (pas de test sur l'ensemble de la chaîne d'authentification incluant Keycloak et Active Directory sous charge). Il confirme la stabilité de l'architecture pour une charge d'accès concurrents modérée, sans se substituer à une campagne de test de charge complète.
