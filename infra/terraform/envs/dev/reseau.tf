# Réseau minimal : un VPC dédié, un sous-réseau public, pas de NAT (32 $ par mois). L'instance n'est
# joignable que par CloudFront : le groupe de sécurité n'accepte que les adresses des serveurs
# CloudFront qui contactent les origines, et nginx exige en plus un en-tête secret (cloudfront.tf).
# Pas de port SSH : l'accès d'administration passe par SSM Session Manager.

resource "aws_vpc" "principal" {
  #checkov:skip=CKV2_AWS_11:Journaux de flux VPC non activés en dev (coût CloudWatch) ; à activer en rct et en prod.
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true # nom DNS public de l'Elastic IP, utilisé comme origine CloudFront

  tags = { Name = local.nom }
}

# Le groupe par défaut du VPC est vidé : aucune ressource ne doit en hériter de règles ouvertes.
resource "aws_default_security_group" "principal" {
  vpc_id = aws_vpc.principal.id
}

resource "aws_internet_gateway" "principal" {
  vpc_id = aws_vpc.principal.id
  tags   = { Name = local.nom }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = var.zone
  map_public_ip_on_launch = false # l'adresse publique est l'Elastic IP

  tags = { Name = "${local.nom}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.principal.id
  }

  tags = { Name = "${local.nom}-public" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Liste gérée par AWS des adresses de CloudFront vers les origines.
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "instance" {
  name        = "${local.nom}-instance"
  description = "ClaimFlow ${var.environnement} : HTTP depuis CloudFront uniquement"
  vpc_id      = aws_vpc.principal.id

  tags = { Name = "${local.nom}-instance" }
}

resource "aws_vpc_security_group_ingress_rule" "depuis_cloudfront" {
  #checkov:skip=CKV_AWS_260:Faux positif : la source est la liste d'adresses de CloudFront, pas 0.0.0.0/0.
  security_group_id = aws_security_group.instance.id
  description       = "nginx, depuis CloudFront"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# Sorties : HTTPS (registre d'images, SSM, S3) et HTTP (miroirs des paquets Ubuntu). Le DNS et
# l'heure passent par les services internes du VPC, que les groupes de sécurité ne filtrent pas.
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.instance.id
  description       = "HTTPS sortant"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "http" {
  security_group_id = aws_security_group.instance.id
  description       = "HTTP sortant (paquets Ubuntu)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
