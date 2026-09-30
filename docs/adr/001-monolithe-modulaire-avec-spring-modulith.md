# ADR-001 · Monolithe modulaire avec Spring Modulith

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

Un seul développeur, un seul domaine métier, 50 utilisateurs simultanés visés. Une transition d'état et son entrée d'audit doivent réussir ou échouer ensemble.

## Décision

Un seul déployable Spring Boot découpé en 9 modules. Les frontières sont vérifiées à chaque build par `ApplicationModules.verify()` : pas de cycle, pas d'accès aux packages internes d'un autre module.

## Options écartées

Microservices : déploiement indépendant, mais transactions distribuées, sagas, traçage réparti et une facture AWS multipliée, sans bénéfice à cette échelle. Monolithe en couches classique : simple, mais rien n'empêche les dépendances croisées de s'installer.

## Conséquences

Une base, des transactions locales, un seul pipeline. Un module peut être extrait plus tard (notification et pilotage sont les premiers candidats) puisqu'il ne communique que par son API publique et ses événements. L'application monte en charge d'un bloc.
