# Infrastructure AWS (Terraform)

Décisions : ADR-015. Mise en route complète, de la création du compte à l'adresse HTTPS :
[`docs/runbooks/aws-demarrage.md`](../../docs/runbooks/aws-demarrage.md).

| Dossier | Contenu | Appliqué par | État |
|---|---|---|---|
| `bootstrap/` | bucket d'état, confiance OIDC GitHub, rôles de la CI, limite de permissions, budget | l'administrateur, une fois, depuis son poste | local (+ copie dans le bucket) |
| `envs/dev/` | VPC, instance EC2, volume de données, buckets, CloudFront, arrêt nocturne, paramètres SSM | Actions → **Infra** (plan en pull request, apply manuel) | `s3://<bucket>/envs/dev/` |
| `envs/dev/fichiers/` | `user_data`, `docker-compose.yml`, modèle nginx, `deployer.sh`, sauvegarde | copiés dans S3 et relus par l'instance à chaque déploiement | |

```
Navigateur ──HTTPS──▶ CloudFront ─┬─ /*                          ──▶ S3 (SPA, privé, OAC)
                                  └─ /api/* /auth/* /actuator/health ──HTTP + en-tête secret──▶ EC2
                                                                    nginx ▶ API · Keycloak ▶ PostgreSQL
GitHub Actions ──OIDC──▶ rôle claimflow-ci-dev ──▶ Terraform · SSM Run Command · S3 · CloudFront
```

## Règles

- Aucune ressource n'est créée ni modifiée à la main dans la console : tout passe par une pull
  request, avec le plan dans le résumé du job.
- Pas de secret dans Terraform quand on peut l'éviter : les mots de passe des bases sont générés sur
  l'instance et rangés dans SSM.
- Chaque exception de sécurité est justifiée en ligne (`#checkov:skip=CODE:raison`). La CI exécute
  `terraform fmt`, `terraform validate` et Checkov sur les deux piles.
- `terraform.tfvars` n'est jamais versionné (`.gitignore`). Après le premier `terraform init` de
  l'amorçage, committer `.terraform.lock.hcl` pour figer les empreintes des fournisseurs.

## Vérifier localement

```bash
terraform fmt -check -recursive infra/terraform
terraform -chdir=infra/terraform/envs/dev init -backend=false && terraform -chdir=infra/terraform/envs/dev validate
```
