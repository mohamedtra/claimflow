output "bucket_etat" {
  description = "Bucket de l'état Terraform des environnements."
  value       = aws_s3_bucket.etat.bucket
}

output "role_ci_plan" {
  description = "Rôle pris par la CI sur les pull requests (terraform plan)."
  value       = aws_iam_role.ci_plan.arn
}

output "role_ci_dev" {
  description = "Rôle pris par la CI dans l'environnement GitHub dev."
  value       = aws_iam_role.ci_dev.arn
}

output "commandes_github" {
  description = "Les trois variables GitHub à créer, prêtes à copier."
  value       = <<-EOT
    gh variable set TF_STATE_BUCKET   --repo ${var.depot_github} --body "${aws_s3_bucket.etat.bucket}"
    gh variable set AWS_PLAN_ROLE_ARN --repo ${var.depot_github} --body "${aws_iam_role.ci_plan.arn}"
    gh variable set AWS_ROLE_ARN      --repo ${var.depot_github} --env dev --body "${aws_iam_role.ci_dev.arn}"
  EOT
}
