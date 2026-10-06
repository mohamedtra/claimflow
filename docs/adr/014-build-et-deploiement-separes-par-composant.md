# ADR-014 · Build automatique et déploiement manuel, séparés par composant

- **Statut :** acceptée
- **Date :** 06/10/2026
- **Remplace en partie :** la chaîne unique de la section 3.10 du dossier projet

## Contexte

L'API et la SPA sont deux livrables indépendants (deux images Docker), reliés uniquement par le
contrat OpenAPI. Avec une chaîne unique, une modification de la SPA relançait le build de l'API, et
l'inverse, et tout se déployait ensemble. En entreprise, on construit automatiquement à chaque
changement, mais on choisit quand et où on déploie, et la production passe par une approbation.

## Décision

**Build automatique, un workflow par composant**, à chaque pull request et à chaque fusion sur main :

| Workflow | Jobs (contrôles exigés par la protection de main) | Déclenché si |
|---|---|---|
| Qualité commune | Messages de commit · Contrat d'API · Secrets et dépendances | toujours |
| Build backend | API · tests et qualité · Image api | `api/`, `docs/openapi/` ou le workflow change |
| Build frontend | SPA · lint, types, tests · Image web | `web/`, `docs/openapi/` ou le workflow change |

Les sept contrôles restent exigés. Un job ignoré parce que son composant n'a pas changé compte comme
réussi : une pull request qui ne touche que la SPA n'attend pas le build de l'API. Sur main, chaque
build publie son image, étiquetée par l'empreinte du commit.

**Déploiement manuel, un workflow par composant** (`Deploy backend`, `Deploy frontend`), lancé
depuis l'onglet Actions en choisissant la référence et l'environnement :

| Environnement | Lancé depuis | Garde-fous |
|---|---|---|
| dev | main | aucune approbation |
| rct | un tag `vX.Y.Z-rc.N` | règle de l'environnement GitHub sur les tags |
| prod | un tag `vX.Y.Z` | approbation obligatoire, et l'image doit être exactement celle qui est en rct |

Le déploiement ne reconstruit jamais rien : il retrouve l'image publiée par le build de main et lui
ajoute les étiquettes de l'environnement et de la version (même empreinte). La logique commune est
dans `_deploiement.yml`.

## Options écartées

- **Deux dépôts** (backend et frontend) : isolation totale, mais le contrat d'API serait dupliqué ou
  publié comme paquet, et une évolution du contrat demanderait deux pull requests coordonnées.
- **Filtres `paths` au niveau du workflow** : plus simples, mais un workflow non déclenché laisse ses
  contrôles exigés « en attente » et bloque la pull request. Le filtre est donc fait par un job.
- **Déploiement automatique en dev à chaque fusion** : pratique, mais l'objectif est ici de montrer
  le modèle « build automatique, déploiement décidé ». Il pourra être ajouté pour dev seulement.

## Conséquences

- Le backend et le frontend se déploient indépendamment. C'est sûr tant que le contrat reste
  compatible (oasdiff bloque tout changement cassant) et que les migrations suivent le motif
  expand / contract. Quand le contrat évolue, on déploie l'API avant la SPA.
- La version d'un composant est le dernier commit qui l'a modifié. Cela suppose un seul commit par
  push sur main, garanti par la protection de main (fusion « squash » uniquement).
- Les filtres de chemins de `build-*.yml` et la liste `chemins` de `deploy-*.yml` doivent rester
  identiques ; un commentaire le rappelle dans chaque fichier.
- Tant que les environnements AWS n'existent pas (EN-08, EN-09, EN-12), le déploiement s'arrête après
  la promotion de l'image, avec un message explicite.
