data "aws_caller_identity" "current" {}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "region" {
  value = var.region
}

output "registry" {
  description = "Repository URL to tag and push the app image to."
  value       = aws_ecr_repository.app.repository_url
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}
