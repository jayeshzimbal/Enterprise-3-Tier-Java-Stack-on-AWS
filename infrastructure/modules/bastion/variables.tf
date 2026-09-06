variable "environment" { type = string }
variable "public_subnet_id" { type = string }
variable "security_group_ids" { type = list(string) }
variable "key_name" { type = string }