# Paramètres SSM lus par le déploiement (_deploiement.yml) et par l'instance (deployer.sh).
# Les identifiants des ressources n'apparaissent ainsi ni dans le dépôt ni dans GitHub.
#
#   /claimflow/dev/instance-id, bucket-spa, …  écrits ici, par Terraform
#   /claimflow/dev/version/api                 écrit par le déploiement (version déployée)
#   /claimflow/dev/secrets/*                   créés sur l'instance au premier déploiement

locals {
  parametres = {
    "instance-id"         = aws_instance.principale.id
    "bucket-spa"          = aws_s3_bucket.spa.bucket
    "bucket-exploitation" = aws_s3_bucket.exploitation.bucket
    "distribution-id"     = aws_cloudfront_distribution.principale.id
    "url"                 = "https://${aws_cloudfront_distribution.principale.domain_name}"
  }
}

resource "aws_ssm_parameter" "infra" {
  #checkov:skip=CKV2_AWS_34:Identifiants de ressources, pas des secrets : lisibles sans déchiffrement.
  for_each = local.parametres

  name  = "${local.ssm}/${each.key}"
  type  = "String"
  value = each.value
}

# Secret partagé entre CloudFront (en-tête ajouté à chaque requête) et nginx (qui le vérifie).
resource "aws_ssm_parameter" "secret_origine" {
  #checkov:skip=CKV_AWS_337:Clé gérée aws/ssm ; une clé KMS dédiée coûte 1 $ par mois (ADR-015).
  name  = "${local.ssm}/origine/secret"
  type  = "SecureString"
  value = random_password.secret_origine.result
}
