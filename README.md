# ClaimFlow

Plateforme de gestion des sinistres pour un assureur IARD (habitation et automobile) :
déclaration en ligne, instruction, expertise, indemnisation, acceptation de l'offre par l'assuré
et journal d'audit immuable.

Projet de démonstration construit de bout en bout pour montrer une pratique réelle de
**Java 25, Spring Boot 4, Spring Security, PostgreSQL et Vue.js 3**, avec des choix
d'architecture argumentés dans [`docs/adr`](docs/adr).

> Toutes les données (assurés, contrats, sinistres) sont **fictives**.

## Démarrer en local

Prérequis : Docker, Java 25, Maven 3.9, Node.js 22.

[![CI](https://github.com/mohamedtra/claimflow/actions/workflows/ci.yml/badge.svg)](https://github.com/mohamedtra/claimflow/actions/workflows/ci.yml)

```bash
make up        # PostgreSQL, Keycloak, stockage objet, Mailpit, ClamAV
make api       # API Spring Boot sur http://localhost:8080 (profil local, jeu de démo)
make web       # SPA Vue 3 sur http://localhost:5173
make test      # tous les tests : unitaires, architecture, intégration (Testcontainers), front
```

Ou toute la pile en conteneurs : `make up-app`.

| Service | URL | Identifiants de démo |
|---|---|---|
| API (santé) | http://localhost:8080/actuator/health | — |
| Keycloak | http://localhost:8180 | `admin` / `admin` |
| Stockage objet (console) | http://localhost:9001 | `claimflow` / `claimflow-dev` |
| Mailpit | http://localhost:8025 | — |

Comptes du realm `claimflow` (mot de passe `demo` pour tous) :
`claire.martin` (assurée), `julien.moreau` et `amelie.roux` (gestionnaires), `nadia.benali` (experte),
`sophie.laurent` (responsable), `karim.haddad` (administrateur).

## Organisation du dépôt

```
api/      Spring Boot 4 + Spring Modulith : un package racine par module métier
bff/      Backend for Frontend (sprint 1)
web/      Vue 3 + TypeScript + Vite
infra/    Docker Compose local, Terraform AWS (release 2)
docs/     ADR, contrat OpenAPI, backlog, journal, rétrospectives, recette, runbooks
scripts/  outillage GitHub (labels, import du backlog)
```

## Comment on travaille

- Sprints de deux semaines, backlog dans GitHub Projects ([`docs/backlog`](docs/backlog)).
- Branches courtes, pull request obligatoire, [Conventional Commits](CONTRIBUTING.md).
- La CI bloque toute fusion si un contrôle échoue : tests, architecture, qualité,
  dépendances vulnérables, secrets, compatibilité du contrat d'API.
- Les règles suivies par l'assistant IA sont écrites dans [`AGENTS.md`](AGENTS.md).

## Démonstrations de fin de sprint

| Sprint | Vidéo | Ce qui est montré |
|---|---|---|
| 0 | à venir | Le socle se construit, se teste et démarre en une commande ; une violation d'architecture est bloquée par la CI |
