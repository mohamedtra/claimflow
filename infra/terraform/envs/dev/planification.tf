# Arrêt la nuit, démarrage le matin (EventBridge Scheduler, gratuit à ce volume). Instance arrêtée :
# ni calcul ni licence facturés ; seuls les volumes et l'adresse IP restent dus. Le déploiement
# démarre l'instance s'il la trouve arrêtée.

data "aws_iam_policy_document" "confiance_scheduler" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.compte]
    }
  }
}

resource "aws_iam_role" "planificateur" {
  count                = var.arret_nocturne ? 1 : 0
  name                 = "${local.nom}-planificateur"
  path                 = "/claimflow/"
  assume_role_policy   = data.aws_iam_policy_document.confiance_scheduler.json
  permissions_boundary = data.aws_iam_policy.limite_roles.arn
}

data "aws_iam_policy_document" "planificateur" {
  statement {
    actions   = ["ec2:StartInstances", "ec2:StopInstances"]
    resources = [aws_instance.principale.arn]
  }
}

resource "aws_iam_role_policy" "planificateur" {
  count  = var.arret_nocturne ? 1 : 0
  name   = "demarrer-arreter"
  role   = aws_iam_role.planificateur[0].id
  policy = data.aws_iam_policy_document.planificateur.json
}

locals {
  horaires = var.arret_nocturne ? {
    arret     = { heure = var.heure_arret, action = "stopInstances" }
    demarrage = { heure = var.heure_demarrage, action = "startInstances" }
  } : {}
}

resource "aws_scheduler_schedule" "instance" {
  #checkov:skip=CKV_AWS_297:La charge utile (un identifiant d'instance) n'a rien de sensible : clé gérée par AWS.
  for_each = local.horaires

  name                         = "${local.nom}-${each.key}"
  description                  = "ClaimFlow ${var.environnement} : ${each.key} de l'instance"
  schedule_expression          = "cron(0 ${each.value.heure} * * ? *)"
  schedule_expression_timezone = "Europe/Paris"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:${each.value.action}"
    role_arn = aws_iam_role.planificateur[0].arn
    input    = jsonencode({ InstanceIds = [aws_instance.principale.id] })
  }
}
