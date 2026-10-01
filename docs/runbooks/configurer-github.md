# Configurer GitHub pour ClaimFlow

État au 01/10/2026 : le dépôt est en ligne, la CI est verte, et les étiquettes, les 11 jalons
(un par sprint) et les 43 issues du backlog sont créés. Il reste quatre réglages que seul le
propriétaire du dépôt peut faire.

## 1. Réglages du dépôt, environnements et protection de main (une commande)

Prérequis : [GitHub CLI](https://cli.github.com/) installé et authentifié (`gh auth login`).

```bash
git clone https://github.com/mohamedtra/claimflow.git && cd claimflow
scripts/github/configurer-parametres.sh mohamedtra/claimflow
```

Le script est idempotent. Il applique :

- fusion « squash » uniquement, suppression des branches fusionnées, sujets du dépôt ;
- détection des secrets avec blocage au push, alertes de vulnérabilités ;
- environnements `dev` (depuis main), `rct` (tags `vX.Y.Z-rc.N`) et `prod` (tags `vX.Y.Z`,
  avec votre approbation obligatoire) ;
- protection de main (`scripts/github/regles-main.json`) : pull request obligatoire, les sept
  contrôles de la CI verts, historique linéaire, pas de force-push.

> Les noms des contrôles exigés doivent correspondre aux noms des jobs de
> `.github/workflows/ci.yml`. Si un job est renommé, mettre à jour `regles-main.json`.

## 2. Tableau GitHub Projects (interface web, environ 5 minutes)

1. https://github.com/users/mohamedtra/projects → **New project** → modèle **Board**, nom « ClaimFlow ».
2. **Workflows** → activer **Auto-add to project** avec le filtre `repo:mohamedtra/claimflow is:issue`,
   puis **Add items** → sélectionner toutes les issues du dépôt (les 43 existantes).
3. Colonnes du champ **Status** : Backlog, Prête, En cours, En revue, En recette, Terminée ;
   limite de 2 cartes sur « En cours ».
4. Ajouter un champ **Points** (nombre) ; la valeur figure dans l'étiquette `points:*` de chaque issue.
5. Ajouter une vue **Table** groupée par **Milestone** : chaque jalon est un sprint.
6. Ajouter une vue **Roadmap** groupée par étiquette `release:*`.

## 3. SonarQube Cloud

1. Se connecter à https://sonarcloud.io avec le compte GitHub et importer le dépôt
   (gratuit pour un dépôt public). Organisation : `mohamedtra`, clé : `mohamedtra_claimflow`.
2. Choisir l'analyse par la CI (et non l'analyse automatique).
3. Créer un jeton et l'ajouter au dépôt : `gh secret set SONAR_TOKEN --repo mohamedtra/claimflow`.
4. Garder le quality gate « Sonar way » : 80 % de couverture et au plus 3 % de duplication sur le
   code nouveau.

Tant que `SONAR_TOKEN` n'est pas défini, l'étape d'analyse est ignorée et le reste de la CI tourne.

## 4. Renovate

Installer l'application [Renovate](https://github.com/apps/renovate) sur le dépôt `claimflow`. La
configuration est dans `renovate.json` : mises à jour groupées le lundi matin, actions GitHub
épinglées par empreinte.

## Vérifier

Ouvrir une pull request qui ne change qu'une ligne du README : les sept contrôles doivent passer et
la fusion n'est possible qu'une fois tous verts.

### Pull request de démonstration : violation d'architecture

Sur une branche `demo/violation-architecture`, ajouter dans le module `indemnisation` une classe qui
importe `fr.claimflow.sinistre.domain.Statut` (package interne d'un autre module). Le job
« API · tests et qualité » échoue sur `ArchitectureTest`, et la fusion est impossible.
Ne pas fusionner : fermer la pull request après la démonstration.

## Recréer le backlog dans un autre dépôt

`scripts/github/labels.sh` puis `scripts/github/importer-backlog.sh` (voir `docs/backlog/README.md`).
