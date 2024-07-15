provider "aws" {
  region  = var.region
  profile = "vendor1"
}

data "aws_availability_zones" "available" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  connector_external_url = "https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.3.0.Final/debezium-connector-postgres-2.3.0.Final-plugin.tar.gz"
  connector              = "debezium-connector-postgres/debezium-connector-postgres-2.3.0.Final.jar"

  tags = {
    Example = var.name
  }
}

# ################################################################################
# # MSK Cluster
# ################################################################################

module "msk_cluster" {
  source  = "terraform-aws-modules/msk-kafka-cluster/aws"
  version = "2.6.0"

  name                   = var.name
  kafka_version          = "3.5.1"
  number_of_broker_nodes = length(distinct(data.aws_subnet.vendor1_private_subnets[*].availability_zone))

  broker_node_client_subnets  = tolist(data.aws_subnet.vendor1_private_subnets[*].id)
  broker_node_instance_type   = "kafka.t3.small"
  broker_node_security_groups = [module.security_group.security_group_id]

  # Connect custom plugin(s)
  connect_custom_plugins = {
    debezium = {
      name         = "debezium-postgresql"
      description  = "Debezium PostgreSQL connector"
      content_type = "JAR"

      s3_bucket_arn     = module.s3_bucket.s3_bucket_arn
      s3_file_key       = aws_s3_object.debezium_connector.id
      s3_object_version = aws_s3_object.debezium_connector.version_id

      timeouts = {
        create = "20m"
      }
    }
  }
  cloudwatch_log_group_name = "vendor1"
  # Connect worker configuration
  create_connect_worker_configuration           = true
  connect_worker_config_name                    = var.name
  connect_worker_config_description             = "Example connect worker configuration"
  connect_worker_config_properties_file_content = <<-EOT
    key.converter=org.apache.kafka.connect.storage.StringConverter
    value.converter=org.apache.kafka.connect.storage.StringConverter
  EOT

  tags = local.tags
}

# ################################################################################
# # Supporting Resources
# ################################################################################

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket_prefix = var.name
  versioning = {
    enabled = true
  }

  # Allow deletion of non-empty bucket for testing
  force_destroy = true

  attach_deny_insecure_transport_policy = true
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}

resource "aws_s3_object" "debezium_connector" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = local.connector
  source = local.connector

  depends_on = [
    null_resource.debezium_connector
  ]
}

resource "null_resource" "debezium_connector" {
  provisioner "local-exec" {
    command = <<-EOT
      wget -c ${local.connector_external_url} -O connector.tar.gz \
        && tar -zxvf connector.tar.gz  ${local.connector} \
        && rm *.tar.gz
    EOT
  }
}
