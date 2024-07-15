variable "name" {
  description = "Name of the VPC and MSK Cluster"
  type        = string
  default     = "vendor1"
}
variable "region" {
  description = "Region"
  default     = "ap-southeast-1"
  type        = string
}
variable "vpc_cidr" {
  description = "VPC CIDR. This should be a valid private (RFC 1918) CIDR range"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-07802c7ec880cc955"
}

variable "subnet_ids" {
  type    = list(string)
  default = ["subnet-0b632622e61239e53", "subnet-0a1752ad606822388"]
}
