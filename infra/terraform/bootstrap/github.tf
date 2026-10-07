# Fédération OIDC : GitHub Actions obtient des identifiants AWS temporaires (une heure) en
# présentant un jeton signé par GitHub. Aucune clé d'accès AWS n'est stockée dans GitHub.
#
# Deux rôles, distingués par le « sub » du jeton, c'est-à-dire par le contexte du workflow :
#   claimflow-ci-plan  pull requests du dépôt   lecture seule : terraform plan
#   claimflow-ci-dev   environnement GitHub dev  déploiement de dev (infra et applications)
# Une pull request ouverte depuis un fork n'obtient pas de jeton OIDC (règle de GitHub).
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "confiance_plan" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.depot_github}:pull_request"]
    }
  }
}

data "aws_iam_policy_document" "confiance_dev" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Seuls les jobs qui déclarent « environment: dev » prennent ce rôle ; l'environnement GitHub
    # n'accepte que la branche main (scripts/github/configurer-parametres.sh).
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.depot_github}:environment:dev"]
    }
  }
}

# --- Rôle de lecture : terraform plan sur les pull requests ----------------------------------------

resource "aws_iam_role" "ci_plan" {
  name                 = "claimflow-ci-plan"
  description          = "GitHub Actions, pull requests : terraform plan (lecture seule)"
  assume_role_policy   = data.aws_iam_policy_document.confiance_plan.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "ci_plan_lecture" {
  role       = aws_iam_role.ci_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ReadOnlyAccess ne permet pas de déchiffrer : le plan doit relire le paramètre SSM chiffré qui
# porte le secret partagé entre CloudFront et l'origine. Déchiffrement limité aux appels via SSM.
data "aws_iam_policy_document" "ci_plan_dechiffrement" {
  #checkov:skip=CKV_AWS_356:Clé gérée par AWS (aws/ssm) : restreinte par la condition kms:ViaService.
  statement {
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ci_plan_dechiffrement" {
  name   = "dechiffrement-ssm"
  role   = aws_iam_role.ci_plan.id
  policy = data.aws_iam_policy_document.ci_plan_dechiffrement.json
}

# --- Rôle de déploiement de dev -----------------------------------------------------------------------

resource "aws_iam_role" "ci_dev" {
  name                 = "claimflow-ci-dev"
  description          = "GitHub Actions, environnement dev : terraform apply et déploiements"
  assume_role_policy   = data.aws_iam_policy_document.confiance_dev.json
  max_session_duration = 3600
}

# PowerUserAccess : tous les services sauf IAM, Organizations et la gestion du compte.
resource "aws_iam_role_policy_attachment" "ci_dev_services" {
  role       = aws_iam_role.ci_dev.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM, au strict nécessaire : créer les rôles de l'environnement (instance EC2, planificateur),
# uniquement sous le chemin /claimflow/ et toujours avec la limite de permissions ci-dessous.
# Sans cette limite, un rôle capable de créer des rôles peut s'attribuer des droits d'administrateur.
data "aws_iam_policy_document" "ci_dev_iam" {
  #checkov:skip=CKV_AWS_356:Seule la lecture IAM (Get*, List*) porte sur toutes les ressources : Terraform en a besoin pour relire l'existant.
  statement {
    sid = "CreerRolesAvecLimite"
    actions = [
      "iam:CreateRole",
      "iam:PutRolePermissionsBoundary",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
    ]
    resources = ["arn:aws:iam::${local.compte}:role/claimflow/*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.limite_roles.arn]
    }
  }

  statement {
    sid = "GererRoles"
    actions = [
      "iam:DeleteRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
      "iam:UpdateAssumeRolePolicy",
    ]
    resources = ["arn:aws:iam::${local.compte}:role/claimflow/*"]
  }

  statement {
    sid = "ProfilsInstance"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
    ]
    resources = ["arn:aws:iam::${local.compte}:instance-profile/claimflow/*"]
  }

  statement {
    sid       = "TransmettreRoles"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.compte}:role/claimflow/*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com", "scheduler.amazonaws.com"]
    }
  }

  statement {
    sid       = "LectureIam"
    actions   = ["iam:Get*", "iam:List*"]
    resources = ["*"]
  }

  statement {
    sid    = "LimiteIntouchable"
    effect = "Deny"
    actions = [
      "iam:DeleteRolePermissionsBoundary",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ci_dev_iam" {
  name   = "iam-limite"
  role   = aws_iam_role.ci_dev.id
  policy = data.aws_iam_policy_document.ci_dev_iam.json
}

# --- Limite de permissions des rôles créés par les environnements ---------------------------------
# Plafond de ce que peuvent faire l'instance EC2 et le planificateur, quelles que soient les
# politiques que Terraform leur attache : SSM, les buckets du projet, démarrer et arrêter les
# instances du projet. Aucune action IAM.
data "aws_iam_policy_document" "limite_roles" {
  #checkov:skip=CKV_AWS_111:Actions de l'agent SSM (celles d'AmazonSSMManagedInstanceCore) : elles ne se restreignent pas par ressource.
  #checkov:skip=CKV_AWS_356:Idem, et kms limité aux appels via SSM et S3 par la condition kms:ViaService.
  statement {
    sid = "AgentSsm"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:DescribeDocument",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:GetManifest",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:PutInventory",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ParametresDuProjet"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:PutParameter",
    ]
    resources = ["arn:aws:ssm:${var.region}:${local.compte}:parameter/claimflow/*"]
  }

  statement {
    sid = "BucketsDuProjet"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::claimflow-*", "arn:aws:s3:::claimflow-*/*"]
  }

  statement {
    sid       = "DemarrerArreterInstancesDuProjet"
    actions   = ["ec2:StartInstances", "ec2:StopInstances"]
    resources = ["arn:aws:ec2:${var.region}:${local.compte}:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Projet"
      values   = ["claimflow"]
    }
  }

  statement {
    sid       = "ChiffrementViaServices"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.region}.amazonaws.com", "s3.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "limite_roles" {
  name        = "claimflow-limite-roles"
  description = "Limite de permissions des rôles créés par les environnements ClaimFlow"
  policy      = data.aws_iam_policy_document.limite_roles.json
}
