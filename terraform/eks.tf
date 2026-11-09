module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.k8s_version
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Control plane logging for CloudWatch / audit compliance
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Existing platform VPC: attach to the subnets selected in variables.tf.
  # The network itself is owned outside this stack and never created here.
  vpc_id                   = local.vpc_id
  subnet_ids               = local.private_subnet_ids
  control_plane_subnet_ids = local.private_subnet_ids

  # Allow cluster API server communication from within the shared platform VPC
  cluster_security_group_additional_rules = {
    ingress_vpc = {
      description = "Allow cluster API ingress from shared platform VPC"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  # Enable IAM Roles for Service Accounts (IRSA / OIDC Provider)
  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  # Grants admin access to the AWS SSO role (matching terraform-thesis)
  access_entries = {
    storm_roma_admin = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${var.aws_region}/AWSReservedSSO_StormRomaLabMembers_79b53c86e5da1a3f"
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Native EKS managed addons (matching terraform-thesis)
  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    aws-ebs-csi-driver     = {}
    eks-pod-identity-agent = {}
  }

  # Control Plane & Node EBS KMS Secrets Encryption
  create_kms_key                  = true
  kms_key_description             = "KMS Key for EKS cluster ${var.cluster_name} secrets encryption"
  kms_key_deletion_window_in_days = 7
  enable_kms_key_rotation         = true
  kms_key_owners                  = [data.aws_caller_identity.current.arn]
  kms_key_administrators          = [data.aws_caller_identity.current.arn]
  kms_key_users = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  ]
  kms_key_service_users           = ["autoscaling.amazonaws.com"]

  cluster_encryption_config = {
    resources = ["secrets"]
  }

  # Cluster Security Groups & IAM Governance
  cluster_security_group_tags = {
    Owner    = "so.amin"
    Schedule = "reply-office-hours"
    Cluster  = var.cluster_name
  }

  node_security_group_tags = {
    Owner    = "so.amin"
    Schedule = "reply-office-hours"
    Cluster  = var.cluster_name
  }

  iam_role_tags = {
    Owner    = "so.amin"
    Schedule = "reply-office-hours"
    Cluster  = var.cluster_name
  }

  # Root module tags
  tags = {
    Owner       = "so.amin"
    Schedule    = "reply-office-hours"
    Cluster     = var.cluster_name
    Environment = var.environment
    ManagedBy   = "Terraform-Tekton"
  }

  # --------------------------------------------------------------------------
  # Managed Node Group Defaults
  # --------------------------------------------------------------------------
  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = [var.instance_type]

    attach_cluster_primary_security_group = true

    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }

    iam_role_tags = {
      Owner    = "so.amin"
      Schedule = "reply-office-hours"
      Cluster  = var.cluster_name
    }

    tags = {
      Owner       = "so.amin"
      Schedule    = "reply-office-hours"
      Cluster     = var.cluster_name
      Environment = var.environment
    }

    launch_template_tags = {
      Owner       = "so.amin"
      Schedule    = "reply-office-hours"
      Cluster     = var.cluster_name
      Environment = var.environment
      ManagedBy   = "Terraform-Tekton"
    }

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 80
          volume_type           = "gp3"
          iops                  = 3000
          throughput            = 125
          encrypted             = true
          kms_key_id            = module.eks.kms_key_arn
          delete_on_termination = true
        }
      }
    }
  }

  # Primary Managed Node Group
  eks_managed_node_groups = {
    initial = {
      name                     = "${var.cluster_name}-ng"
      use_name_prefix          = false
      iam_role_use_name_prefix = false
      iam_role_name            = "${var.cluster_name}-node-role"
      min_size                 = var.min_nodes
      max_size                 = var.max_nodes
      desired_size             = var.desired_nodes

      instance_types = [var.instance_type]
      capacity_type  = "ON_DEMAND"

      labels = {
        role        = "worker"
        environment = var.environment
        owner       = "so.amin"
      }

      tags = {
        Owner       = "so.amin"
        Schedule    = "reply-office-hours"
        Cluster     = var.cluster_name
        Environment = var.environment
      }

      launch_template_tags = {
        Owner       = "so.amin"
        Schedule    = "reply-office-hours"
        Cluster     = var.cluster_name
        Environment = var.environment
        ManagedBy   = "Terraform-Tekton"
      }
    }
  }
}
