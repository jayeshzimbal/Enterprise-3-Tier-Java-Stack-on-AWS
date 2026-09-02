output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = module.rds.rds_instance_endpoint
}
