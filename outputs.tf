output "role_arn" {
  description = "ARN da role. No workflow: aws-actions/configure-aws-credentials → role-to-assume"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Nome da role"
  value       = aws_iam_role.this.name
}

output "oidc_provider_arn" {
  description = "ARN do provedor OIDC do GitHub na conta"
  value       = local.oidc_provider_arn
}

output "subjects" {
  description = "Valores de sub aceitos na trust policy (bom para conferir com o CloudTrail)"
  value       = local.subjects
}
