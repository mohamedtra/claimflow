# Règles pour les assistants IA

Ce fichier s'adresse à tout assistant de code (Claude, Copilot, Cursor…) qui intervient sur ClaimFlow.
Il est aussi un contrat pour les humains : le code produit avec l'IA suit exactement les mêmes règles.

## Contexte

ClaimFlow gère des sinistres d'assurance. Les règles métier sont numérotées RG-01 à RG-14 et
décrites dans le dossier projet. Les décisions d'architecture sont dans `docs/adr/`.
Langue du code métier : **français** (classes, méthodes, tables). Langue technique : anglais accepté
pour les termes consacrés (repository, controller…).

## Architecture : ce qui est interdit

| Interdit | Pourquoi | À faire à la place |
|---|---|---|
| Modifier un statut par `setStatut()` ou `PATCH /sinistres/{id}` | Contourne la machine à états (ADR-004) | Une méthode de commande sur l'agrégat, une opération `POST .../<commande>` |
| `double`, `float` pour un montant | Erreurs d'arrondi (ADR-012) | Value object `Montant` (BigDecimal) ; chaîne `"3876.00"` en JSON |
| Lire ou joindre les tables d'un autre module | Couple les modules (ADR-001) | Appeler l'API publique du module (package racine) ou écouter ses événements |
| Clé étrangère entre schémas de modules | Empêche l'extraction d'un module | Référence par identifiant, sans FK |
| Importer un sous-package (`domain`, `infrastructure`…) d'un autre module | Les tests Spring Modulith échouent | Passer par le package racine du module |
| Jeton JWT dans `localStorage` ou `sessionStorage` | Exposé au XSS (ADR-003) | Le BFF garde les jetons ; le navigateur n'a qu'un cookie HttpOnly |
| Pagination par `OFFSET` / `Pageable` sur les listes | Coût linéaire (ADR-007) | Pagination par curseur (`Window`, `ScrollPosition`) |
| Stocker un fichier en base | ADR-008 | Stockage objet + métadonnées |
| `UPDATE` ou `DELETE` sur `audit.entree_audit` | Journal en ajout seul (ADR-010) | Nouvelle entrée |
| Secret, mot de passe ou jeton dans le dépôt | Dépôt public | Variables d'environnement, Secrets Manager |
| Ressource AWS créée ou modifiée à la main (console, CLI) | Dérive entre Terraform et la réalité (ADR-015) | Pull request sur `infra/terraform`, plan relu dans la CI |
| Clé d'accès AWS longue durée, pour la CI ou sur un poste | Fuite = accès permanent au compte | OIDC pour GitHub Actions, `aws login` pour un humain |
| `#checkov:skip` sans raison | Exception invisible en revue | `#checkov:skip=CODE:raison` sur la ressource concernée |

## Ce qui est attendu

- Toute règle métier est testée, et le test cite son identifiant (`RG-05`) dans son nom ou son commentaire.
- Tout changement d'API commence par `docs/openapi/claimflow.yaml`. Le code généré n'est jamais modifié.
- Une migration Flyway est **additive** et reste compatible avec la version précédente de l'application
  (expand / contract). Une migration appliquée n'est jamais modifiée.
- Les erreurs d'API suivent RFC 9457 (Problem Details) et citent la règle concernée.
- Les dates métier sont des `LocalDate` ; les horodatages des `Instant` en UTC.
- Pas de dépendance ajoutée sans justification dans la pull request.

## Versions : pièges connus (ADR-013)

Le projet est en **Java 25, Spring Boot 4.1, Spring Modulith 2.1, Testcontainers 2**. Ne pas proposer
la syntaxe de Spring Boot 3 : `spring-boot-starter-web` devient `spring-boot-starter-webmvc`,
Jackson est en version 3 (`tools.jackson`), `@MockBean` devient `@MockitoBean`, et
`PostgreSQLContainer` est dans `org.testcontainers.postgresql`.

## Avant de proposer du code

1. Lire l'ADR concerné.
2. Écrire ou adapter le test d'abord quand une règle métier est en jeu.
3. Lancer `make test` : unitaires, architecture et intégration doivent passer.
4. Signaler explicitement toute hypothèse faite sur une règle métier.
