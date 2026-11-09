variable "cluster_name" {
  description = "Unique identifier for the EKS cluster and dependent resources"
  type        = string
  default     = "cluster-lunedi"
}

variable "aws_region" {
  description = "AWS Target Region"
  type        = string
  default     = "eu-west-1"
}

variable "k8s_version" {
  description = "Desired Kubernetes control plane and node group version"
  type        = string
  default     = "1.37"
}

variable "vpc_id" {
  description = "ID of the existing platform VPC the cluster is attached to (never created or destroyed by this stack)"
  type        = string
  default     = "vpc-04f3bbc90663bf4d7"
}

variable "vpc_private_subnet_ids" {
  description = "Private subnets in the existing VPC used for the control plane ENIs and worker nodes"
  type        = list(string)
  default     = ["subnet-09be94e727ebafc91", "subnet-000bafe5ce7ab10c2", "subnet-07dd17a5cfed9eef2"]
}

variable "vpc_public_subnet_ids" {
  description = "Public subnets in the existing VPC used by internet-facing load balancers (may be empty)"
  type        = list(string)
  default     = ["subnet-0e84f9ff3dc9b7eb0", "subnet-0a14d565f4807e1d1", "subnet-07cf8a8c392da4a16"]
}

variable "instance_type" {
  description = "EC2 instance family and sizing for the Managed Node Group"
  type        = string
  default     = "m6i.large"
}

variable "min_nodes" {
  description = "Minimum capacity of the primary worker node group"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum autoscaling boundary for worker nodes"
  type        = number
  default     = 6
}

variable "desired_nodes" {
  description = "Initial target capacity for worker nodes"
  type        = number
  default     = 2
}

variable "environment" {
  description = "Deployment lifecycle stage"
  type        = string
  default     = "production"
}

variable "owner_tag" {
  description = "Mandatory ownership tag required by governance policies"
  type        = string
  default     = "so.amin"
}


variable "vpc_cidr" {
  description = "CIDR block of the shared platform VPC used for internal cluster API ingress"
  type        = string
  default     = "10.1.0.0/16"
}
