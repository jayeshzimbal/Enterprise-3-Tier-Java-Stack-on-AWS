variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for ALB placement"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs attached to ALB"
  type        = list(string)
}