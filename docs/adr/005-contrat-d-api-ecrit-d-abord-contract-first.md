# ADR-005 · Contrat d'API écrit d'abord (contract-first)

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

Le front et le back avancent en parallèle, et le contrat d'API est ce que l'on relit en revue.

## Décision

`docs/openapi/claimflow.yaml` est la source de vérité. OpenAPI Generator produit les interfaces Spring (`interfaceOnly`) et le client TypeScript de la SPA. En CI, Spectral contrôle le style et oasdiff détecte les changements incompatibles.

## Options écartées

Code-first avec springdoc : rapide, mais le contrat découle du code, dérive sans que personne ne le voie, et sa revue se fait trop tard.

## Conséquences

Le code généré n'est jamais modifié à la main. La configuration du générateur est à maintenir. Un changement d'API commence toujours par une modification du YAML.

## Amendement du 01/10/2026

Côté SPA, les types sont générés par `openapi-typescript` et les appels passent par `openapi-fetch`,
au lieu d'un client produit par OpenAPI Generator : aucun code d'exécution généré, seulement des
types, et un client de quelques kilo-octets. La CI régénère les types et échoue s'ils diffèrent de
ceux du dépôt. Côté Spring, OpenAPI Generator 7.25 produit les interfaces avec les options
`useSpringBoot4` et `useJackson3`.

## Amendement du 08/11/2026 : SPA en Angular (ADR-017)

Côté SPA, `ng-openapi-gen` remplace `openapi-typescript` et `openapi-fetch` : une fonction par
opération, appelée par le service `Api` et `HttpClient`. Le code produit va dans `web/src/app/api`, est
versionné et n'est jamais modifié à la main. La CI le régénère et échoue s'il diffère de celui du
dépôt, fichiers nouveaux compris. L'adresse du contrat (`servers`) n'est pas utilisée : la SPA appelle
la même origine (`provideApiConfiguration('')`), où le BFF relaie vers l'API.
