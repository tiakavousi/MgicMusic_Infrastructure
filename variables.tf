# variables.tf
variable "aws_access_key" {
    description = "The IAM public access key"
}

variable "aws_secret_key" {
    description = "IAM secret access key"
}

variable "aws_region" {
    description = "The AWS region things are created in"
}

variable "subnets" {
  description = "List of subnets"
  type        = list(string)
}

# variable "security_groups" {
#   description = "List of security groups"
#   type        = list(string)
# }

# variable "vpc_id" {
#   description = "The VPC ID"
#   type        = string
# }

variable "private_subnets" {
  description = "List of private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnets"
  type        = list(string)
}

