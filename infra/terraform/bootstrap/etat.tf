# Bucket de l'état Terraform des environnements (une clé par environnement : envs/dev/…).
# Versionné pour pouvoir revenir à un état précédent, chiffré, jamais public. Le verrou est un
# fichier .tflock posé dans le même bucket (use_lockfile, Terraform >= 1.10) : pas de DynamoDB.
data "aws_caller_identity" "courant" {}

locals {
  compte = data.aws_caller_identity.courant.account_id
}

resource "aws_s3_bucket" "etat" {
  #checkov:skip=CKV_AWS_144:Réplication inter-régions inutile pour l'état d'un projet de démonstration ; le versionnement suffit.
  #checkov:skip=CKV_AWS_18:Journal d'accès S3 non activé : CloudTrail trace déjà les appels, et un second bucket ajoute un coût sans usage.
  #checkov:skip=CKV2_AWS_62:Pas de notification d'événement : aucun consommateur.
  #checkov:skip=CKV_AWS_145:Chiffrement SSE-S3 plutôt qu'une clé KMS dédiée (1 $ par mois) : suffisant pour ce projet, voir ADR-015.

  bucket = "claimflow-tfstate-${local.compte}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "etat" {
  bucket = aws_s3_bucket.etat.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "etat" {
  bucket = aws_s3_bucket.etat.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "etat" {
  bucket                  = aws_s3_bucket.etat.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "etat" {
  bucket = aws_s3_bucket.etat.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Les anciennes versions de l'état sont gardées 90 jours : de quoi revenir en arrière après une
# erreur, sans accumuler indéfiniment.
resource "aws_s3_bucket_lifecycle_configuration" "etat" {
  bucket = aws_s3_bucket.etat.id

  rule {
    id     = "anciennes-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# L'état contient des identifiants de ressources : accès en HTTPS uniquement.
data "aws_iam_policy_document" "etat" {
  statement {
    sid       = "HttpsUniquement"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.etat.arn, "${aws_s3_bucket.etat.arn}/*"]

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

resource "aws_s3_bucket_policy" "etat" {
  bucket = aws_s3_bucket.etat.id
  policy = data.aws_iam_policy_document.etat.json

  depends_on = [aws_s3_bucket_public_access_block.etat]
}
