# Une seule distribution CloudFront, en HTTPS sur son domaine *.cloudfront.net (pas de nom de
# domaine en dev). Elle sert la SPA depuis S3 et transmet à l'instance ce qui relève du serveur :
#   /api/*            l'API
#   /actuator/health  le contrôle de santé (utilisé par le déploiement)
#   /auth/*           Keycloak
# Le BFF (sprint 1) ajoutera ses chemins (/bff/*, /oauth2/*, /login/*).
#
# Entre CloudFront et l'instance, le trafic est en HTTP : une origine HTTPS exige un certificat
# public pour son nom, donc un domaine. Risque accepté en dev seulement, avec des données fictives
# (ADR-015). L'en-tête secret empêche de contourner CloudFront.

resource "random_password" "secret_origine" {
  length  = 40
  special = false
}

resource "aws_cloudfront_origin_access_control" "spa" {
  name                              = "${local.nom}-spa"
  description                       = "Accès de CloudFront au bucket de la SPA"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Routage de la SPA : une adresse sans extension (/sinistres/42) renvoie index.html, le routeur
# Vue fait le reste. Ce n'est pas une page d'erreur globale : elle masquerait les 404 de l'API.
resource "aws_cloudfront_function" "routage_spa" {
  name    = "${local.nom}-routage-spa"
  runtime = "cloudfront-js-2.0"
  comment = "Routes de la SPA vers index.html"
  publish = true
  code    = <<-JS
    function handler(event) {
      var requete = event.request;
      var dernier = requete.uri.split('/').pop();
      if (dernier.indexOf('.') === -1) {
        requete.uri = '/index.html';
      }
      return requete;
    }
  JS
}

# En-têtes de sécurité de la SPA, alignés sur web/nginx.conf.
resource "aws_cloudfront_response_headers_policy" "spa" {
  #checkov:skip=CKV_AWS_259:HSTS présent (un an, sous-domaines) ; « preload » n'a pas de sens sur un domaine *.cloudfront.net.
  name    = "${local.nom}-entetes-spa"
  comment = "En-têtes de sécurité de la SPA"

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; frame-ancestors 'none'"
      override                = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
    }
  }
}

data "aws_cloudfront_cache_policy" "optimise" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "sans_cache" {
  name = "Managed-CachingDisabled"
}

# Transmet tout ce que le navigateur envoie (cookies, en-têtes, paramètres) sauf l'en-tête Host,
# remplacé par le nom de l'origine.
data "aws_cloudfront_origin_request_policy" "tout_sauf_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

locals {
  chemins_serveur = ["/api/*", "/auth/*", "/actuator/health"]
}

resource "aws_cloudfront_distribution" "principale" {
  #checkov:skip=CKV_AWS_68:Pas de WAF en dev (5 $ par mois minimum) ; prévu en prod (ADR-015).
  #checkov:skip=CKV2_AWS_47:Idem : pas de WAF en dev.
  #checkov:skip=CKV_AWS_86:Journaux d'accès CloudFront non activés en dev (coût de stockage, aucun usage).
  #checkov:skip=CKV_AWS_174:Certificat par défaut *.cloudfront.net : la version TLS minimale n'est réglable qu'avec un certificat propre (domaine, prévu en prod).
  #checkov:skip=CKV2_AWS_42:Idem : pas de domaine ni de certificat ACM en dev.
  #checkov:skip=CKV_AWS_310:Une seule origine par type de contenu : pas de bascule en dev.
  #checkov:skip=CKV_AWS_374:Pas de restriction géographique : application de démonstration ouverte.
  enabled             = true
  comment             = "ClaimFlow ${var.environnement}"
  default_root_object = "index.html"
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100" # Europe et Amérique du Nord : les points de présence les moins chers

  origin {
    origin_id                = "spa"
    domain_name              = aws_s3_bucket.spa.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.spa.id
  }

  origin {
    origin_id   = "instance"
    domain_name = aws_eip.principale.public_dns

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 30
    }

    custom_header {
      name  = "X-Origine-CloudFront"
      value = random_password.secret_origine.result
    }
  }

  default_cache_behavior {
    target_origin_id           = "spa"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.optimise.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.spa.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.routage_spa.arn
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.chemins_serveur
    content {
      path_pattern             = ordered_cache_behavior.value
      target_origin_id         = "instance"
      viewer_protocol_policy   = "https-only"
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods           = ["GET", "HEAD"]
      compress                 = true
      cache_policy_id          = data.aws_cloudfront_cache_policy.sans_cache.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.tout_sauf_host.id
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
