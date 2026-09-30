# ADR-003 · Backend for Frontend : aucun jeton dans le navigateur

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

Une SPA ne peut pas garder de secret, et un jeton placé dans localStorage est lisible par n'importe quel script injecté (XSS). Le brouillon IETF « OAuth 2.0 for Browser-Based Applications » présente le BFF comme l'architecture la plus protectrice.

## Décision

Un BFF Spring Cloud Gateway Server MVC réalise la connexion OIDC, conserve les jetons en session serveur (Spring Session JDBC) et relaie les appels vers l'API avec le filtre `TokenRelay`. Le navigateur ne reçoit qu'un cookie HttpOnly, Secure, SameSite=Lax. Les requêtes modifiantes portent un jeton CSRF.

## Options écartées

SPA publique avec PKCE et jetons en mémoire : acceptable, mais le jeton reste accessible au JavaScript et le rafraîchissement est fragile. Sessions applicatives sans OIDC : perte du SSO.

## Conséquences

Un conteneur de plus. Les sessions sont partagées entre instances par la base, sans Redis. SPA et BFF sont servis sous le même domaine, donc pas de CORS. L'API n'est jamais exposée à Internet.
