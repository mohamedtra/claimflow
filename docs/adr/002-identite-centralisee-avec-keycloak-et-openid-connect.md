# ADR-002 · Identité centralisée avec Keycloak et OpenID Connect

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

Trois populations : personnel (SSO et MFA), assurés, experts externes. Écrire une gestion de mots de passe maison serait un risque sans valeur ajoutée.

## Décision

Un realm `claimflow`. Le BFF est un client confidentiel (code d'autorisation + PKCE). L'API est un *resource server* qui vérifie la signature du JWT par les clés JWKS, l'émetteur, l'audience `claimflow-api` et l'expiration. Les rôles du realm deviennent des autorités Spring. Jetons d'accès de 5 minutes.

## Options écartées

Spring Authorization Server : davantage de code à écrire et à maintenir. Amazon Cognito : lié à AWS et moins pratique en local. Le standard OIDC laisse la porte ouverte à une migration.

## Conséquences

Keycloak est un composant à exploiter (base, mises à jour, deux instances en production). En local, il démarre dans Docker avec un realm importé et des comptes de démonstration.
