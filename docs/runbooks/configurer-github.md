# Configurer GitHub pour ClaimFlow

À faire une fois, à la création du dépôt. Durée : environ 20 minutes.
Prérequis : [GitHub CLI](https://cli.github.com/) authentifié (`gh auth login`), avec la portée
projet (`gh auth refresh -s project`).

Dans les commandes, remplacer `OWNER` par votre identifiant GitHub.

## 1. Créer le dépôt public et pousser le socle

```bash
gh repo create OWNER/claimflow --public --description "Gestion des sinistres : Java 25, Spring Boot 4, Vue 3" --source . --push
```

Remplacer ensuite `OWNER` dans `.github/CODEOWNERS`, `api/pom.xml` (propriétés Sonar) et
`docs/openapi/claimflow.yaml` (contact), puis committer :
`chore(repo): renseigner le propriétaire du dépôt`.

## 2. Protéger la branche main

```bash
gh api repos/OWNER/claimflow/rulesets --method POST --input scripts/github/regles-main.json
```

Effet : pull request obligatoire, fusion « squash » uniquement, historique linéaire, pas de
suppression ni de force-push, et les sept contrôles de la CI doivent être verts.

> Les noms des contrôles exigés doivent correspondre aux noms des jobs de
> `.github/workflows/ci.yml`. Si un job est renommé, mettre à jour `regles-main.json`.

## 3. Étiquettes et backlog

```bash
scripts/github/labels.sh OWNER/claimflow
gh project create --owner OWNER --title "ClaimFlow"          # noter le numéro affiché
scripts/github/importer-backlog.sh OWNER/claimflow <numéro>
```

Dans le projet (interface web) :

1. Ajouter un champ **Itération** : durée 2 semaines, première itération le lundi 5 octobre 2026.
2. Ajouter un champ **Points** (nombre) et le renseigner depuis le titre des cartes.
3. Créer une vue **Tableau** avec les colonnes : Backlog, Prête, En cours, En revue, En recette,
   Terminée ; limiter « En cours » à 2 cartes.
4. Créer une vue **Roadmap** groupée par étiquette `release:*`.
5. Placer EN-01 à EN-06 dans l'itération « Sprint 0 ».

## 4. SonarQube Cloud

1. Se connecter à https://sonarcloud.io avec le compte GitHub et importer le dépôt
   (gratuit pour un dépôt public).
2. Choisir l'analyse par la CI (et non l'analyse automatique).
3. Créer un jeton et l'ajouter au dépôt : `gh secret set SONAR_TOKEN --repo OWNER/claimflow`.
4. Garder le quality gate « Sonar way » : 80 % de couverture et au plus 3 % de duplication sur le
   code nouveau.

Tant que `SONAR_TOKEN` n'est pas défini, l'étape d'analyse est ignorée et le reste de la CI tourne.

## 5. Renovate

Installer l'application [Renovate](https://github.com/apps/renovate) sur le dépôt. La configuration
est dans `renovate.json` : mises à jour groupées le lundi matin, actions GitHub épinglées par
empreinte.

## 6. Vérifier

Ouvrir une pull request qui ne change qu'une ligne du README : les sept contrôles doivent passer.
Puis ouvrir la pull request de démonstration du sprint 0 (voir ci-dessous) : elle doit être bloquée.

### Pull request de démonstration : violation d'architecture

Sur une branche `demo/violation-architecture`, ajouter dans le module `indemnisation` une classe qui
importe `fr.claimflow.sinistre.domain.Statut` (package interne d'un autre module). Le job
« API · tests et qualité » échoue sur `ArchitectureTest`, et la fusion est impossible.
Ne pas fusionner : fermer la pull request après la démonstration.
