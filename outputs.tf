# outputs.tf

# -------------------------
# VPC and Subnets
# -------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public[0].id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private[0].id
}

output "private_subnet_2_id" {
  description = "ID of the second private subnet"
  value       = aws_subnet.private[1].id
}

output "private_subnet_3_id" {
  description = "ID of the third private subnet"
  value       = aws_subnet.private[1].id
}

output "public_subnet_2_id" {
  description = "ID of the second public subnet"
  value       = aws_subnet.public[1].id
}

output "public_subnet_3_id" {
  description = "ID of the third public subnet"
  value       = aws_subnet.public[1].id
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = aws_acm_certificate.ssl.arn
}

# -------------------------
# ECS Cluster and Service
# -------------------------
output "ecs_cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.app.name
}

# -------------------------
# RDS PostgreSQL
# -------------------------
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_rds_cluster.postgresql.endpoint
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_rds_cluster.postgresql.port
}

# -------------------------
# ElastiCache Redis
# -------------------------
output "redis_primary_endpoint" {
  description = "Redis cluster primary endpoint"
  value       = aws_elasticache_replication_group.redis_cluster.primary_endpoint_address
}

output "s3_backup_bucket" {
  description = "S3 backup bucket name"
  value       = aws_s3_bucket.code_bucket_backup.bucket
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.redis_cluster.port
}

# -------------------------
# S3 Bucket
# -------------------------
output "s3_code_bucket_name" {
  description = "S3 bucket name for user code uploads"
  value       = aws_s3_bucket.code_bucket.bucket
}

# -------------------------
# ALB
# -------------------------
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

# -------------------------
# ECR Repository
# -------------------------
output "ecr_repository_url" {
  description = "ECR repository URL for container images"
  value       = aws_ecr_repository.app.repository_url
}

# -------------------------
# S3 VPC Endpoint
# -------------------------
output "s3_vpc_endpoint_id" {
  description = "S3 VPC Endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

# -------------------------
# CloudFront
# -------------------------
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.paas_cdn.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.paas_cdn.id
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID for Route53"
  value       = aws_cloudfront_distribution.paas_cdn.hosted_zone_id
}

# -------------------------
# Git Integration Webhook
# -------------------------
output "webhook_url" {
  description = "Webhook URL for Git integration"
  value       = "${aws_api_gateway_rest_api.git_webhooks.execution_arn}/prod/webhook/{app_name}"
}

output "aurora_endpoint" {
  description = "Aurora Serverless endpoint"
  value       = aws_rds_cluster.postgresql.endpoint
}

