# Une instance EC2 qui porte la pile en conteneurs (fichiers/docker-compose.yml). Elle est
# remplaçable : les données PostgreSQL sont sur un volume séparé, rattaché à la nouvelle instance,
# et la configuration est relue depuis S3 à chaque déploiement.

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_policy" "limite_roles" {
  name = "claimflow-limite-roles" # créée par infra/terraform/bootstrap
}

# --- Rôle de l'instance ---------------------------------------------------------------------------

data "aws_iam_policy_document" "confiance_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name                 = "${local.nom}-instance"
  path                 = "/claimflow/"
  assume_role_policy   = data.aws_iam_policy_document.confiance_ec2.json
  permissions_boundary = data.aws_iam_policy.limite_roles.arn
}

# Agent SSM : Run Command (déploiements) et Session Manager (accès sans SSH).
resource "aws_iam_role_policy_attachment" "instance_ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "instance" {
  #checkov:skip=CKV_AWS_356:kms limité aux appels via SSM par la condition kms:ViaService (clé gérée aws/ssm).
  statement {
    sid = "ParametresEtSecrets"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = ["arn:aws:ssm:${var.region}:${local.compte}:parameter${local.ssm}/*"]
  }

  # Les mots de passe de PostgreSQL et de Keycloak sont générés sur l'instance au premier
  # déploiement (fichiers/deployer.sh) : ils ne passent jamais par Terraform ni par son état.
  statement {
    sid       = "CreerSecrets"
    actions   = ["ssm:PutParameter"]
    resources = ["arn:aws:ssm:${var.region}:${local.compte}:parameter${local.ssm}/secrets/*"]
  }

  statement {
    sid       = "Dechiffrement"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.region}.amazonaws.com"]
    }
  }

  statement {
    sid       = "LireConfiguration"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.exploitation.arn}/config/*"]
  }

  statement {
    sid       = "ListerConfiguration"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.exploitation.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["config/*"]
    }
  }

  statement {
    sid       = "DeposerSauvegardes"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.exploitation.arn}/sauvegardes/*"]
  }
}

resource "aws_iam_role_policy" "instance" {
  name   = "claimflow"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.instance.json
}

resource "aws_iam_instance_profile" "instance" {
  name = "${local.nom}-instance"
  path = "/claimflow/"
  role = aws_iam_role.instance.name
}

# --- Volume de données ------------------------------------------------------------------------------

resource "aws_ebs_volume" "donnees" {
  #checkov:skip=CKV_AWS_189:Chiffré avec la clé gérée par AWS ; une clé KMS dédiée coûte 1 $ par mois (ADR-015).
  availability_zone = var.zone
  size              = var.taille_donnees_gio
  type              = "gp3"
  encrypted         = true

  tags = { Name = "${local.nom}-donnees" }
}

# --- Instance ---------------------------------------------------------------------------------------

resource "aws_instance" "principale" {
  #checkov:skip=CKV_AWS_126:Supervision détaillée payante ; la supervision de base (5 minutes) suffit en dev.
  #checkov:skip=CKV_AWS_88:Adresse publique nécessaire sans NAT ; l'entrée est limitée à CloudFront (reseau.tf).
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.type_instance
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile   = aws_iam_instance_profile.instance.name
  ebs_optimized          = true
  monitoring             = false

  # IMDSv2 obligatoire ; une seule étape réseau : les conteneurs n'atteignent pas les
  # identifiants de l'instance.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = templatefile("${path.module}/fichiers/user-data.sh.tftpl", {
    environnement       = var.environnement
    region              = var.region
    bucket_exploitation = aws_s3_bucket.exploitation.bucket
    volume_donnees      = replace(aws_ebs_volume.donnees.id, "-", "")
  })
  user_data_replace_on_change = true

  tags = { Name = local.nom }

  lifecycle {
    # Une nouvelle image Ubuntu ne remplace pas l'instance d'elle-même ; les correctifs de
    # sécurité sont appliqués par unattended-upgrades.
    ignore_changes = [ami]
  }

  # La configuration doit être dans S3 avant le premier démarrage.
  depends_on = [aws_s3_object.config]
}

resource "aws_volume_attachment" "donnees" {
  device_name                    = "/dev/sdf"
  volume_id                      = aws_ebs_volume.donnees.id
  instance_id                    = aws_instance.principale.id
  stop_instance_before_detaching = true
}

# Adresse fixe : son nom DNS public sert d'origine à CloudFront et ne change pas quand
# l'instance est arrêtée la nuit ou remplacée.
resource "aws_eip" "principale" {
  domain = "vpc"
  tags   = { Name = local.nom }
}

resource "aws_eip_association" "principale" {
  allocation_id = aws_eip.principale.id
  instance_id   = aws_instance.principale.id
}
