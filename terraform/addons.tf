
# ------------------------------------------------------------------------------
# EKS Blueprints Addons: AWS Load Balancer Controller, Metrics Server, ExternalDNS
# ------------------------------------------------------------------------------
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # AWS Load Balancer Controller with explicit Owner tag enforcement
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [
      {
        name  = "defaultTags.Owner"
        value = "so.amin"
      },
      {
        name  = "defaultTags.Cluster"
        value = var.cluster_name
      }
    ]
  }

  # Metrics Server for HPA and cluster metrics
  enable_metrics_server = true

  # ExternalDNS for automated Route53 record management
  enable_external_dns = true
  external_dns = {
    set = [
      {
        name  = "txtOwnerId"
        value = "${var.cluster_name}-external-dns"
      }
    ]
  }

  tags = {
    Owner       = "so.amin"
    Cluster     = var.cluster_name
    Environment = var.environment
    ManagedBy   = "Terraform-Tekton"
  }
}

