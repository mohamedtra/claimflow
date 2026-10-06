# Deux buckets :
#   spa           les fichiers de la SPA, lus par CloudFront uniquement (OAC)
#   exploitation  la configuration de l'instance (config/) et les sauvegardes PostgreSQL

locals {
  buckets = {
    spa          = "${local.nom}-spa-${local.compte}"
    exploitation = "${local.nom}-exploitation-${local.compte}"
  }
}

resource "aws_s3_bucket" "spa" {
  #checkov:skip=CKV_AWS_144:Pas de réplication : la SPA se republie depuis son image.
  #checkov:skip=CKV_AWS_18:Pas de journal d'accès S3 en dev (coût, aucun usage).
  #checkov:skip=CKV2_AWS_62:Pas de notification d'événement : aucun consommateur.
  #checkov:skip=CKV_AWS_145:SSE-S3 ; une clé KMS imposerait de l'autoriser à CloudFront, sans gain ici.
  #checkov:skip=CKV_AWS_21:Pas de versionnement : chaque version de la SPA est dans son image.
  #checkov:skip=CKV2_AWS_61:Pas de cycle de vie : s3 sync --delete retire les anciens fichiers.
  bucket        = local.buckets.spa
  force_destroy = true
}

resource "aws_s3_bucket" "exploitation" {
  #checkov:skip=CKV_AWS_144:Pas de réplication inter-régions en dev.
  #checkov:skip=CKV_AWS_18:Pas de journal d'accès S3 en dev (coût, aucun usage).
  #checkov:skip=CKV2_AWS_62:Pas de notification d'événement : aucun consommateur.
  #checkov:skip=CKV_AWS_145:SSE-S3 suffisant en dev (ADR-015).
  #checkov:skip=CKV_AWS_21:Pas de versionnement : la configuration est versionnée dans git, les sauvegardes sont horodatées.
  bucket        = local.buckets.exploitation
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "chiffrement" {
  for_each = { spa = aws_s3_bucket.spa.id, exploitation = aws_s3_bucket.exploitation.id }
  bucket   = each.value
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "prive" {
  for_each                = { spa = aws_s3_bucket.spa.id, exploitation = aws_s3_bucket.exploitation.id }
  bucket                  = each.value
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "proprietaire" {
  for_each = { spa = aws_s3_bucket.spa.id, exploitation = aws_s3_bucket.exploitation.id }
  bucket   = each.value
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "exploitation" {
  bucket = aws_s3_bucket.exploitation.id

  rule {
    id     = "sauvegardes"
    status = "Enabled"
    filter {
      prefix = "sauvegardes/"
    }
    expiration {
      days = var.duree_sauvegardes_jours
    }
  }

  rule {
    id     = "envois-interrompus"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# Le bucket de la SPA n'est lisible que par cette distribution CloudFront.
data "aws_iam_policy_document" "spa" {
  statement {
    sid       = "CloudFrontUniquement"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.spa.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.principale.arn]
    }
  }

  statement {
    sid       = "HttpsUniquement"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.spa.arn, "${aws_s3_bucket.spa.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "spa" {
  bucket     = aws_s3_bucket.spa.id
  policy     = data.aws_iam_policy_document.spa.json
  depends_on = [aws_s3_bucket_public_access_block.prive]
}

data "aws_iam_policy_document" "exploitation" {
  statement {
    sid       = "HttpsUniquement"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.exploitation.arn, "${aws_s3_bucket.exploitation.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "exploitation" {
  bucket     = aws_s3_bucket.exploitation.id
  policy     = data.aws_iam_policy_document.exploitation.json
  depends_on = [aws_s3_bucket_public_access_block.prive]
}

# Configuration de l'instance, relue à chaque déploiement : la modifier ne remplace pas l'instance.
# Le realm Keycloak est celui de l'environnement local (utilisateurs de démonstration fictifs).
locals {
  config = merge(
    {
      for f in ["docker-compose.yml", "nginx.conf.modele", "init-postgres.sh", "deployer.sh", "sauvegarder.sh"] :
      f => "${path.module}/fichiers/${f}"
    },
    { "claimflow-realm.json" = "${path.module}/../../../docker/keycloak/claimflow-realm.json" },
  )
}

resource "aws_s3_object" "config" {
  for_each = local.config

  bucket = aws_s3_bucket.exploitation.id
  key    = "config/${each.key}"
  source = each.value
  etag   = filemd5(each.value)

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.chiffrement]
}
