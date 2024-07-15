# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.0"

#   name = var.name
#   cidr = var.vpc_cidr

#   azs              = local.azs
#   public_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
#   private_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 3)]
#   database_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 6)]

#   create_database_subnet_group = true
#   enable_nat_gateway           = true
#   single_nat_gateway           = true

#   tags = local.tags
# }

data "aws_vpc" "vendor1" {
  id = var.vpc_id
}

data "aws_subnet" "vendor1_private_subnets" {
  count = length(var.subnet_ids)
  id    = var.subnet_ids[count.index]
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.name}_msk_sg"
  description = "Security group for ${var.name}"
  vpc_id      = data.aws_vpc.vendor1.id

  ingress_cidr_blocks = tolist(data.aws_subnet.vendor1_private_subnets[*].cidr_block)
  ingress_rules = [
    "kafka-broker-tcp",
    "kafka-broker-tls-tcp"
  ]

  tags = local.tags
}
