# Démarrer sur AWS, de A à Z

De la création du compte à l'adresse HTTPS de l'environnement dev. Compter une heure la première
fois, dont 15 minutes d'attente. Décisions : ADR-015 (option A, région Paris, offre payante avant
six mois).

| Étape | Où | Durée |
|---|---|---|
| A. Sécuriser le compte racine | console AWS | 10 min |
| B. Créer votre utilisateur d'administration | console AWS | 10 min |
| C. Installer les outils et connecter le CLI | votre poste | 10 min |
| D. Lancer l'amorçage Terraform | votre poste | 5 min |
| E. Donner à GitHub les trois variables | votre poste | 2 min |
| F. Rendre publiques les deux images | github.com | 2 min |
| G. Créer l'environnement dev | GitHub Actions | 10 min |
| H. Déployer l'API puis la SPA | GitHub Actions | 10 min |

---

## A. Sécuriser le compte racine

Le compte racine (l'adresse e-mail de création du compte) a tous les droits, y compris fermer le
compte. On le protège, puis on ne s'en sert plus qu'exceptionnellement.

1. Se connecter sur https://console.aws.amazon.com en choisissant **Utilisateur racine**.
2. En haut à droite, cliquer sur le nom du compte → **Informations d'identification de sécurité**
   (*Security credentials*).
3. Section **Authentification multi-facteur (MFA)** → **Attribuer un dispositif MFA**.
   - Nom : `racine` ;
   - type : **Clé d'accès ou clé de sécurité** (passkey du téléphone ou de l'ordinateur, le plus sûr)
     ou, à défaut, **Application d'authentification** (Google Authenticator, Microsoft
     Authenticator, 1Password…) ;
   - pour une application : scanner le QR code, puis saisir **deux codes successifs**.
4. Sur la même page, section **Clés d'accès** : elle doit être **vide**. Le compte racine ne doit
   jamais avoir de clé d'accès.
5. Menu du compte → **Compte** (*Account*) → section **Accès des utilisateurs et rôles IAM aux
   informations de facturation** → **Modifier** → cocher **Activer l'accès IAM** → **Mettre à jour**.
   Sans cela, votre futur utilisateur d'administration ne verra ni la facture ni les budgets.
6. **Billing and Cost Management** → **Préférences de facturation** → **Préférences d'alerte** →
   **Modifier** → cocher **Recevoir les alertes d'utilisation de l'offre gratuite AWS** (votre
   e-mail) → **Mettre à jour**.
7. Noter dans votre agenda, **cinq mois après la date de création du compte** : « Passer AWS en offre
   payante ». À faire depuis **Billing and Cost Management** → bouton **Mettre à niveau le plan**
   (*Upgrade plan*). Les crédits restants sont conservés. Sans ce passage, AWS suspend le compte à
   six mois ou à l'épuisement des crédits, et les données sont supprimées après 90 jours.
8. Se déconnecter.

## B. Créer votre utilisateur d'administration

Un utilisateur IAM avec MFA, pour le travail courant. En entreprise, on utiliserait IAM Identity
Center ; il impose AWS Organizations et n'apporte rien pour un compte unique (ADR-015).

1. Se reconnecter en racine (une dernière fois), ouvrir le service **IAM**.
2. **Groupes d'utilisateurs** → **Créer un groupe** : nom `administrateurs`, politique
   `AdministratorAccess` → **Créer**.
3. **Utilisateurs** → **Créer un utilisateur** :
   - nom : `mohamed-admin` ;
   - cocher **Fournir aux utilisateurs l'accès à la console de gestion AWS** → **Je souhaite créer
     un utilisateur IAM** → mot de passe personnalisé (long, dans votre gestionnaire de mots de
     passe) → décocher « doit créer un nouveau mot de passe » ;
   - **Suivant** → **Ajouter l'utilisateur au groupe** → `administrateurs` → **Créer l'utilisateur**.
4. Noter l'**URL de connexion de la console** affichée (`https://<n° de compte>.signin.aws.amazon.com/console`).
   Facultatif : **Tableau de bord IAM** → **Alias de compte** → `claimflow-mohamed`, pour une URL
   plus lisible.
5. Se déconnecter du compte racine, se connecter avec cette URL en `mohamed-admin`.
6. Menu du compte → **Informations d'identification de sécurité** → **Attribuer un dispositif MFA**,
   comme à l'étape A.3 (nom : `mohamed-admin`).
7. Ne **pas** créer de clé d'accès : le CLI utilisera `aws login` (étape C), qui délivre des
   identifiants temporaires.

À partir d'ici, tout se fait en `mohamed-admin`. Le compte racine ne sert plus que pour la
facturation si la console l'exige (passage en offre payante).

## C. Installer les outils et connecter le CLI

**AWS CLI 2.32 ou plus** (pour `aws login`) et **Terraform 1.10 ou plus** (verrou d'état dans S3).

| Système | AWS CLI | Terraform |
|---|---|---|
| macOS | `brew install awscli` | `brew tap hashicorp/tap && brew install hashicorp/tap/terraform` |
| Windows | `winget install Amazon.AWSCLI` | `winget install Hashicorp.Terraform` |
| Linux | [installeur officiel](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | [dépôt HashiCorp](https://developer.hashicorp.com/terraform/install) |

Optionnel, pour ouvrir un terminal sur l'instance plus tard : le
[plugin Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html).

```bash
aws --version          # aws-cli/2.32 ou plus
terraform version      # Terraform v1.10 ou plus

# Profil « claimflow », région Paris, connexion par le navigateur (mot de passe + MFA).
aws configure set region eu-west-3 --profile claimflow
aws login --profile claimflow

# Vérification : doit afficher …:user/mohamed-admin
aws sts get-caller-identity --profile claimflow
```

Terraform lit les identifiants du CLI par un second profil, qui les lui transmet (ajouter ces lignes
à la fin de `~/.aws/config`, ou `%USERPROFILE%\.aws\config` sous Windows) :

```ini
[profile claimflow-terraform]
region = eu-west-3
credential_process = aws configure export-credentials --profile claimflow --format process
```

La session dure jusqu'à 12 heures ; ensuite, relancer `aws login --profile claimflow`.

## D. Lancer l'amorçage Terraform

Crée ce qui doit exister avant que la CI puisse travailler (16 ressources, toutes gratuites) :

- le bucket S3 de l'état Terraform (versionné, chiffré, privé) ;
- la confiance OIDC entre GitHub et AWS, et les deux rôles de la CI (`claimflow-ci-plan` en lecture
  seule, `claimflow-ci-dev` pour l'environnement dev) ;
- la limite de permissions des rôles que la CI créera ;
- le budget mensuel de 50 $, avec alertes par e-mail à 10, 25 et 50 $.

```bash
git clone https://github.com/mohamedtra/claimflow.git   # ou git pull si déjà cloné
cd claimflow/infra/terraform/bootstrap

cp terraform.tfvars.exemple terraform.tfvars
# Ouvrir terraform.tfvars et mettre votre adresse e-mail (ce fichier n'est pas versionné).

export AWS_PROFILE=claimflow-terraform        # PowerShell : $env:AWS_PROFILE = "claimflow-terraform"
terraform init
terraform apply                               # relire le plan, puis répondre « yes »
```

À la fin, Terraform affiche le nom du bucket et les deux rôles. Sauvegarder l'état de l'amorçage
dans le bucket (il reste aussi sur votre poste, ignoré par git) :

```bash
aws s3 cp terraform.tfstate "s3://$(terraform output -raw bucket_etat)/bootstrap/terraform.tfstate"
```

## E. Donner à GitHub les trois variables

Ce ne sont pas des secrets (des noms et des identifiants de rôles), mais ils n'ont pas leur place
dans un dépôt public. Terraform a préparé les commandes :

```bash
terraform output -raw commandes_github
```

Copier-coller les trois lignes affichées. Elles créent :

| Variable | Portée | Rôle |
|---|---|---|
| `TF_STATE_BUCKET` | dépôt | bucket de l'état Terraform |
| `AWS_PLAN_ROLE_ARN` | dépôt | rôle des pull requests (plan en lecture seule) |
| `AWS_ROLE_ARN` | environnement `dev` | rôle des déploiements de dev |

Vérifier :

```bash
gh variable list --repo mohamedtra/claimflow
gh variable list --repo mohamedtra/claimflow --env dev
```

## F. Rendre publiques les deux images

L'instance télécharge les images sans identifiants GitHub : aucun jeton n'est stocké sur la machine.
Les images ne contiennent que le code du dépôt, qui est déjà public.

1. https://github.com/mohamedtra?tab=packages → **claimflow-api** → **Package settings**.
2. **Danger Zone** → **Change visibility** → **Public** → confirmer en tapant le nom.
3. Même chose pour **claimflow-web**.

## G. Créer l'environnement dev

1. GitHub → **Actions** → **Infra** → **Run workflow** → branche `main`, action **plan** → **Run**.
   Lire le résumé du job : une cinquantaine de ressources à créer, aucune à détruire.
2. Relancer avec l'action **apply**. Compter 5 à 10 minutes (la distribution CloudFront est la plus
   longue). Le résumé du job affiche l'adresse : `https://dxxxxxxxxxxxx.cloudfront.net`.

L'instance démarre et s'installe seule (Docker, volume de données, swap, sauvegardes) en 3 à
4 minutes. Son premier déploiement échoue normalement : aucune version n'a encore été déployée.

## H. Déployer l'API puis la SPA

1. **Actions** → **Deploy backend** → **Run workflow** → `main`, environnement **dev**.
   Le job démarre l'instance si besoin, enregistre la version, lance `deployer.sh` par SSM et attend
   `https://…/actuator/health`. Au premier passage, l'instance crée les mots de passe de PostgreSQL
   et de Keycloak dans SSM, puis Keycloak se construit : compter 5 minutes.
2. **Actions** → **Deploy frontend** → `main`, **dev** : fichiers de la SPA vers S3, invalidation de
   CloudFront.
3. Vérifier :
   - `https://<adresse>/` : la SPA ;
   - `https://<adresse>/actuator/health` : `{"status":"UP",…}` ;
   - `https://<adresse>/auth/realms/claimflow/.well-known/openid-configuration` : Keycloak.

C'est l'adresse à donner au client. L'instance s'arrête à 23 h et redémarre à 8 h (heure de Paris).

---

## Exploitation

Toutes les commandes avec `--profile claimflow`. L'identifiant de l'instance est dans SSM :

```bash
INSTANCE=$(aws ssm get-parameter --name /claimflow/dev/instance-id --query Parameter.Value --output text --profile claimflow)
```

| Besoin | Commande |
|---|---|
| Terminal sur l'instance (sans SSH) | `aws ssm start-session --target "$INSTANCE" --profile claimflow` |
| Journaux de l'API (dans le terminal) | `sudo docker logs -f --tail 100 claimflow-api-1` |
| Démarrer l'instance hors horaires | `aws ec2 start-instances --instance-ids "$INSTANCE" --profile claimflow` |
| Lancer une sauvegarde | dans le terminal : `sudo systemctl start claimflow-sauvegarde` |
| Lister les sauvegardes | `aws s3 ls "s3://$(aws ssm get-parameter --name /claimflow/dev/bucket-exploitation --query Parameter.Value --output text --profile claimflow)/sauvegardes/" --profile claimflow` |

**Console d'administration de Keycloak** (bloquée depuis Internet) : tunnel SSM vers le port 8180.

```bash
aws ssm start-session --target "$INSTANCE" --profile claimflow \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["8180"],"localPortNumber":["8180"]}'
# Dans un autre terminal, le mot de passe de l'utilisateur « admin » :
aws ssm get-parameter --name /claimflow/dev/secrets/keycloak-admin --with-decryption \
  --query Parameter.Value --output text --profile claimflow
# Puis ouvrir http://localhost:8180/auth/admin
```

**Restaurer une sauvegarde** (dans le terminal de l'instance) :

```bash
source /etc/claimflow/environnement
aws s3 cp "s3://${BUCKET_EXPLOITATION}/sauvegardes/<horodatage>/claimflow.dump" - |
  sudo docker exec -i claimflow-postgres-1 pg_restore -U postgres --clean --if-exists -d claimflow
```

**Mettre le projet en pause plusieurs semaines** : instance arrêtée, il reste environ 6,50 $ par mois
(disques et adresse IP). Pour tout supprimer, depuis votre poste :

```bash
cd infra/terraform/envs/dev
terraform init -backend-config="bucket=$(gh variable get TF_STATE_BUCKET --repo mohamedtra/claimflow)"
AWS_PROFILE=claimflow-terraform terraform destroy
```

Recréer plus tard : étapes G et H. Les données de dev sont perdues, sauf restauration d'une sauvegarde.

## En cas de problème

| Symptôme | Cause probable | Que faire |
|---|---|---|
| Infra : « Amorçage AWS manquant » | variables GitHub absentes | étape E |
| Infra : `AccessDenied` sur `sts:AssumeRoleWithWebIdentity` | job lancé depuis une autre branche que main, ou « sub » du jeton différent de `sujet_oidc_github` (format immuable `repo:<propriétaire>@<id>/<dépôt>@<id>` depuis le 15/07/2026) | relancer depuis main ; vérifier `sujet_oidc_github` dans l'amorçage, puis `terraform apply` |
| Deploy backend : « Agent SSM » | instance encore en installation (premier démarrage) | relancer dans 5 minutes |
| Deploy backend : `manifest unknown` ou `denied` dans la sortie | images encore privées | étape F |
| `https://…/api/…` répond 403 | requête arrivée sans passer par CloudFront, ou secret d'origine désynchronisé | relancer Deploy backend (il régénère `nginx.conf`) |
| Alerte budget à 10 $ avant la mi-mois | ressource oubliée ou instance jamais arrêtée | **Billing** → **Cost Explorer**, regrouper par service |
