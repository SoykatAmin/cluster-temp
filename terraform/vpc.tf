# ------------------------------------------------------------------------------
# Existing platform VPC
#
# The cluster is attached to a VPC that is provisioned and owned outside this
# stack (default: vpc-04f3bbc90663bf4d7). Nothing here creates a VPC, subnet,
# NAT gateway, internet gateway or route table: the network is read-only from
# Terraform's point of view, so `terraform destroy` removes the cluster and the
# node groups and leaves the shared VPC untouched.
# ------------------------------------------------------------------------------

data "aws_subnet" "private" {
  for_each = toset(var.vpc_private_subnet_ids)

  id = each.value
}

data "aws_subnet" "public" {
  for_each = toset(var.vpc_public_subnet_ids)

  id = each.value
}

locals {
  vpc_id = var.vpc_id

  # Sorted so the lists are stable across plans regardless of the order the
  # subnet IDs are supplied. EKS does not care about ordering.
  private_subnet_ids = sort(var.vpc_private_subnet_ids)
  public_subnet_ids  = sort(var.vpc_public_subnet_ids)

  # `distinct` rather than a map keyed by AZ: a duplicate subnet in the same AZ
  # would otherwise abort evaluation with a raw "duplicate object key" error
  # before the checks below can explain the problem.
  private_subnet_azs = distinct([for s in values(data.aws_subnet.private) : s.availability_zone])
}

# Guardrails. A precondition (not a `check` block) is used deliberately: a
# check only warns and the plan still applies, which is exactly the failure mode
# worth preventing here — attaching the cluster to the wrong VPC or to a single
# AZ is cheap to catch now and expensive to unwind afterwards.
resource "terraform_data" "vpc_guardrails" {
  input = local.vpc_id

  lifecycle {
    precondition {
      condition = alltrue(concat(
        [for s in values(data.aws_subnet.private) : s.vpc_id == local.vpc_id],
        [for s in values(data.aws_subnet.public) : s.vpc_id == local.vpc_id],
      ))
      error_message = "Every subnet in vpc_private_subnet_ids / vpc_public_subnet_ids must belong to VPC ${var.vpc_id}."
    }

    precondition {
      condition = alltrue(concat(
        [for s in values(data.aws_subnet.private) : startswith(s.availability_zone, var.aws_region)],
        [for s in values(data.aws_subnet.public) : startswith(s.availability_zone, var.aws_region)],
      ))
      error_message = "The selected subnets are not in ${var.aws_region}; the VPC and the cluster region must match."
    }

    precondition {
      condition     = length(local.private_subnet_azs) == length(var.vpc_private_subnet_ids)
      error_message = "vpc_private_subnet_ids lists more than one subnet for the same Availability Zone; supply one private subnet per AZ."
    }

    precondition {
      condition     = length(local.private_subnet_azs) >= 2
      error_message = "EKS requires worker subnets in at least two Availability Zones; ${var.vpc_id} was given ${length(local.private_subnet_azs)}."
    }
  }
}
