# ADR-013 · Versions de la plateforme

- **Statut :** acceptée
- **Date :** 01/10/2026

## Contexte

L'ADR-001 prévoyait de figer les versions au démarrage du socle. Le projet démarre en octobre 2026
et doit rester maintenable au moins deux ans.

## Décision

| Brique | Version | Raison |
|---|---|---|
| Java | 25 (LTS) | LTS la plus récente, publiée en septembre 2025 |
| Spring Boot | 4.1.1 | Branche courante ; Spring Framework 7, Jackson 3 |
| Spring Modulith | 2.1.1 | Aligné sur Spring Boot 4.1 |
| Testcontainers | 2.0.x | Géré par Spring Boot |
| PostgreSQL | 18 | Même version en local, en CI et sur AWS |
| Keycloak | 26.7.5 | Dernière version corrective publiée |
| Node.js | 22 (LTS) | Outillage du front |
| Vue / TypeScript / Vite | 3.5 / 5.9 / 8 | Voir ci-dessous pour TypeScript |

Renovate propose chaque lundi les mises à jour ; la CI les valide comme n'importe quelle pull request.

## Options écartées

- **Spring Boot 3.5** : son support open source s'est terminé mi-2026. Démarrer dessus imposerait
  une migration dès les premiers mois.
- **Java 21** : LTS précédente, avec deux ans de support en moins que Java 25.
- **TypeScript 7** (compilateur natif) : `typescript-eslint` et `openapi-typescript` ne le prennent
  pas encore en charge. On reste en 5.9 jusqu'à leur mise à jour.

## Conséquences

Spring Boot 4 change plusieurs habitudes, et beaucoup d'exemples en ligne (et de suggestions d'IA)
reprennent encore la syntaxe de Spring Boot 3 :

- starters modulaires : `spring-boot-starter-webmvc`, `spring-boot-starter-flyway`,
  `spring-boot-starter-security-oauth2-resource-server` ;
- Jackson 3 : packages `tools.jackson` (sauf les annotations, restées en `com.fasterxml.jackson`) ;
- `@MockitoBean` remplace `@MockBean` ;
- Testcontainers 2 : artefacts préfixés (`testcontainers-postgresql`) et classes dans des packages
  dédiés (`org.testcontainers.postgresql.PostgreSQLContainer`).

Ces points sont rappelés dans `AGENTS.md`.
