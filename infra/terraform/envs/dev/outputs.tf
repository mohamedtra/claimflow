output "url" {
  description = "Adresse de l'environnement."
  value       = local.parametres.url
}

output "instance_id" {
  description = "Instance EC2 (accès : aws ssm start-session --target <id>)."
  value       = aws_instance.principale.id
}

output "distribution_id" {
  description = "Distribution CloudFront."
  value       = aws_cloudfront_distribution.principale.id
}

output "bucket_spa" {
  description = "Bucket des fichiers de la SPA."
  value       = aws_s3_bucket.spa.bucket
}

output "bucket_exploitation" {
  description = "Bucket de configuration et de sauvegardes."
  value       = aws_s3_bucket.exploitation.bucket
}
