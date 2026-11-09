output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_id" {
  description = "EKS Cluster Control Plane ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for IAM Roles for Service Accounts (IRSA)"
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  description = "The ID of the existing platform VPC the cluster is attached to"
  value       = local.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets where worker nodes and internal workloads reside"
  value       = local.private_subnet_ids
}

output "public_subnets" {
  description = "List of IDs of public subnets hosting internet-facing ALBs"
  value       = local.public_subnet_ids
}

output "kms_key_arn" {
  description = "KMS Key ARN dedicated to cluster secret envelope encryption"
  value       = module.eks.kms_key_arn
}

output "cluster_security_group_id" {
  description = "Cluster control plane security group ID"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Shared worker node security group ID"
  value       = module.eks.node_security_group_id
}

output "owner_tag" {
  description = "Mandatory ownership tag verified across all infrastructure"
  value       = "so.amin"
}
