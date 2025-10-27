variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "clone-enterprise"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "paasadmin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Clone-Enterprise"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

variable "s3_code_bucket_name" {
  description = "Name for the S3 bucket for user code uploads"
  type        = string
  default     = ""
}

variable "cpu_alarm_threshold" {
  description = "CPU threshold for CloudWatch alarms"
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "Memory threshold for CloudWatch alarms"
  type        = number
  default     = 85
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "github_webhook_secret" {
  description = "GitHub webhook secret for security (optional but recommended)"
  type        = string
  default     = ""
  sensitive   = true
}
