# ADR-017 · Frontend en Angular

- **Statut :** acceptée
- **Date :** 08/11/2026
- **Modifie :** ADR-005 (génération du client de la SPA), ADR-013 (versions du frontend)

## Contexte

La SPA était prévue en Vue 3. La mission visée demande Angular, que le développeur maîtrise mieux.
Au moment de la décision, seul le socle du sprint 0 (un écran de santé) est fusionné. Les écrans de
l'étape 5 (connexion, espace assuré, « Mes contrats ») sont écrits mais pas encore fusionnés. Le coût
de la bascule n'a jamais été aussi bas.

Grâce au BFF (ADR-003), le navigateur n'a ni jeton ni logique d'authentification, seulement un cookie
de session. Le choix du framework ne touche ni l'API, ni le BFF, ni Keycloak, ni l'infrastructure : la
SPA reste un ensemble de fichiers statiques servis par CloudFront.

## Décision

- **Angular 22.2**, dernière version stable. Mise à jour à chaque version majeure (environ tous les
  six mois) avec `ng update`.
- **Angular moderne uniquement** : composants autonomes, signaux, syntaxe de contrôle `@if` et `@for`,
  application sans zone.js. La détection `OnPush` et la syntaxe de contrôle sont imposées par ESLint.
- **Routeur** : écrans chargés à la demande, garde fonctionnelle (`CanActivateFn`) qui lit les droits
  dans les données de route, paramètres d'adresse reçus en entrées des composants
  (`withComponentInputBinding`).
- **HttpClient** : un intercepteur fonctionnel renvoie à la connexion sur un 401 de l'API. La
  protection CSRF intégrée lit le cookie `XSRF-TOKEN` et envoie l'en-tête `X-XSRF-TOKEN`, les noms
  qu'utilise déjà le BFF (`csrf.spa()` de Spring Security).
- **Client généré** : `ng-openapi-gen` produit, à partir du contrat, une fonction par opération et le
  service `Api`. Le code va dans `src/app/api` : il est versionné, jamais modifié à la main, et la CI
  échoue s'il ne correspond plus au contrat.
- **Outillage** : TypeScript 6.0 (exigé par Angular 22), Vitest par le constructeur
  `@angular/build:unit-test` (TestBed, `HttpTestingController`), ESLint avec `angular-eslint`.
- Le serveur de développement reste sur le **port 5173**, avec un proxy vers le BFF : le realm, Docker
  Compose et la documentation ne changent pas.

## Options écartées

- **Rester en Vue 3** : ne correspond plus à la mission visée.
- **Deux SPA** (Vue pour l'assuré, Angular pour le personnel) : on double l'outillage et la CI pour
  une démonstration, ce qui est le risque de sur-ingénierie relevé au cadrage.
- **OpenAPI Generator `typescript-angular`** : il faut télécharger un outil Java, et le code produit
  est plus lourd (un service par étiquette, un module de configuration). `ng-openapi-gen` s'installe
  avec npm et produit des fonctions isolées, que le bundler écarte quand elles ne servent pas.
- **`openapi-typescript` et HttpClient** : n'accepte pas encore TypeScript 6.
- **NgRx** : pas d'état partagé complexe à ce stade. Les signaux et un service par sujet suffisent.
  À réévaluer si un état partagé apparaît (corbeille du gestionnaire, sprint 3).

## Conséquences

- Le dossier `web/` est remplacé en une seule pull request. Le chargement initial pèse environ 73 ko
  compressés, et chaque écran est chargé à la demande.
- Les dépendances changent : la justification demandée par AGENTS.md est cet ADR.
- Renovate limite TypeScript à la plage acceptée par Angular (`< 6.1`).
- La maquette reste la référence visuelle. Les tests de bout en bout (Playwright, étape 5 bis) ne
  dépendent pas du framework : ils visent les attributs `data-test`.
- Angular 23 est attendue vers la fin de 2026 : la mise à jour se fera par `ng update`, dans une pull
  request dédiée.
