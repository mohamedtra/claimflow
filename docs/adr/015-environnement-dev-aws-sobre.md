# ADR-015 · Environnement dev sur AWS : sobre, toujours disponible, décrit par Terraform

- **Statut :** acceptée
- **Date :** 06/10/2026
- **Complète :** ADR-014 (déploiement par composant) et la section 3.11 du dossier projet

## Contexte

Le projet dispose d'un compte AWS neuf (offre gratuite à 100 $ de crédits, à convertir en compte
payant avant six mois) et doit montrer un vrai déploiement dans le cloud dès le sprint 1, pas
seulement en local. L'environnement dev doit :

- être joignable en HTTPS par le client, à tout moment de la journée, sans nom de domaine pour l'instant ;
- coûter le moins possible : la cible est 15 à 20 $ par mois, soit cinq à six mois sur les crédits ;
- être reproductible (Terraform), sans clé AWS longue durée dans GitHub ni secret dans le dépôt public ;
- garder le modèle de l'ADR-014 : build automatique, déploiement manuel par composant.

## Décision

**Option A : une instance, des conteneurs, CloudFront devant.** Région Paris (`eu-west-3`).

| Élément | Choix | Coût mensuel estimé |
|---|---|---|
| Calcul | EC2 `t3.small` (2 vCPU, 2 Gio + 2 Gio de swap), Ubuntu 24.04, arrêtée de 23 h à 8 h (450 h par mois) | ~10,60 $ |
| Conteneurs | PostgreSQL 18, Keycloak, API, nginx (Docker Compose) | inclus |
| Disques | système 20 Gio + données 10 Gio (volume séparé), gp3 chiffrés ; sauvegarde `pg_dump` quotidienne vers S3, 14 jours | ~2,90 $ |
| SPA | bucket S3 privé, lu par CloudFront seulement (OAC) | < 1 $ |
| Accès | une distribution CloudFront, HTTPS sur `*.cloudfront.net` ; `/api/*`, `/auth/*` et `/actuator/health` vers l'instance, le reste vers S3 | < 1 $ |
| Adresse | Elastic IP, origine stable de CloudFront | ~3,60 $ |
| Secrets | SSM Parameter Store (`/claimflow/dev/…`), chiffrés par la clé gérée `aws/ssm` | 0 $ |
| Déploiement | SSM Run Command (`deployer.sh` sur l'instance), `s3 sync` + invalidation pour la SPA | 0 $ |
| Arrêt nocturne | EventBridge Scheduler | 0 $ |
| Garde-fou | budget de 50 $ par mois, alertes à 10, 25 et 50 $, crédits exclus du calcul | 0 $ |
| **Total** | | **~17,50 $** |

**Accès de la CI sans clé :** fédération OIDC entre GitHub et AWS. Deux rôles, créés par une pile
d'amorçage lancée une fois depuis le poste de l'administrateur (`infra/terraform/bootstrap`) :

- `claimflow-ci-plan` (lecture seule) pour les pull requests : `terraform plan` ;
- `claimflow-ci-dev` pour les jobs qui déclarent l'environnement GitHub `dev` (main uniquement) :
  `terraform apply` et déploiements. Il peut tout faire sauf l'IAM ; il ne crée des rôles que sous le
  chemin `/claimflow/` et avec une **limite de permissions** qui leur interdit toute action IAM.

**Secrets :** les mots de passe de PostgreSQL et de Keycloak sont générés sur l'instance au premier
déploiement et rangés dans SSM : ils ne passent ni par Terraform, ni par son état, ni par GitHub.
Seul le secret partagé entre CloudFront et nginx est produit par Terraform (les deux en ont besoin).

**État Terraform :** bucket S3 versionné et chiffré, verrou par fichier (`use_lockfile`, sans DynamoDB).

**Accès humain :** pas de SSH ni de port d'administration ouvert. Session Manager pour le terminal,
tunnel SSM pour la console d'administration de Keycloak, bloquée côté Internet.

## Options écartées

- **ECS Fargate + RDS + ALB + NAT** : l'architecture « de référence », mais environ 90 à 110 $ par mois
  (NAT 32 $, ALB 18 $, RDS 15 $, Fargate 30 $) : les crédits ne tiendraient pas deux mois. Elle reste
  la cible de prod (EN-12), justifiée par la haute disponibilité et les sauvegardes gérées.
- **App Runner** : simple pour l'API, mais Keycloak et PostgreSQL resteraient à héberger ailleurs.
- **Lightsail** : moins cher encore, mais hors de l'écosystème que le client attend (VPC, IAM, SSM,
  CloudFront), et peu démonstratif.
- **Instance allumée en permanence** : 30 % plus chère, sans usage la nuit.
- **IAM Identity Center pour l'accès administrateur** : la bonne pratique multi-comptes, mais elle
  impose AWS Organizations. Pour un compte unique, un utilisateur IAM avec MFA et la commande
  `aws login` (identifiants temporaires, sans clé d'accès) donne le même niveau de sécurité. Identity
  Center viendra avec le compte de prod.

## Risques acceptés en dev, corrigés en prod

| Risque | Pourquoi c'est acceptable en dev | En prod |
|---|---|---|
| Trafic en HTTP entre CloudFront et l'instance | données fictives ; l'origine n'accepte que CloudFront (liste d'adresses AWS + en-tête secret) | nom de domaine, certificat ACM, origine HTTPS ou VPC origin |
| Une seule instance, une seule zone | une coupure de dev n'a pas d'impact métier | ECS sur deux zones, RDS Multi-AZ |
| Pas de WAF, pas de journaux CloudFront ni de flux VPC | coût fixe sans usage à ce stade | activés |
| Chiffrement par clés gérées par AWS, pas de clés KMS dédiées | 1 $ par clé et par mois, sans exigence d'audit | clé KMS dédiée pour les données et les sauvegardes |
| Realm Keycloak de démonstration (comptes fictifs, mot de passe `demo`) | aucune donnée réelle | realm de prod sans comptes de démonstration, secrets des clients dans Secrets Manager |

Chaque exception est justifiée dans le code Terraform (`#checkov:skip=…:raison`) : Checkov la voit
en revue, et une nouvelle exception non justifiée fait échouer la CI.

## Conséquences

- `make up` reste l'environnement de développement quotidien ; dev sur AWS sert à la démonstration
  et à l'intégration continue, avec la même pile de conteneurs.
- Le déploiement de l'API démarre l'instance si elle est arrêtée ; le premier appel après 23 h prend
  donc environ deux minutes.
- Les chemins du BFF (`/bff`, `/oauth2`, `/login`) seront ajoutés à CloudFront et à nginx au sprint 1.
- Avant la fin du sixième mois, le compte passe en offre payante : sinon AWS suspend le compte. Les
  crédits restants sont conservés.

## Amendement du 08/10/2026

Mise en service le 07/10/2026. Le premier `apply` a échoué sur la confiance OIDC : pour les dépôts
créés après le 15/07/2026, GitHub écrit le « sub » des jetons avec les identifiants immuables
(`repo:mohamedtra@36902772/claimflow@1399766812:…`), et non plus `repo:mohamedtra/claimflow:…`.
La condition des rôles est corrigée (PR #46) puis paramétrée (`sujet_oidc_github`). Effet de bord
favorable : un dépôt recréé sous le même nom n'obtiendrait plus les rôles AWS.
