# PaaS Infrastructure – Enterprise Deployment

Enterprise-grade Platform-as-a-Service (PaaS) infrastructure with ECS Fargate + Aurora Serverless, for a Heroku-like clone.

## Architecture

- **Compute**: ECS Fargate with auto-scaling containers (serverless)
- **Load Balancer**: Application Load Balancer with HTTPS/SSL
- **Database**: Aurora Serverless v2 PostgreSQL with automatic scaling
- **Cache**: ElastiCache Redis cluster with Multi-AZ
- **Storage**: S3 with versioning and cross-region replication
- **CDN**: CloudFront distribution for global content delivery
- **Monitoring**: CloudWatch with custom metrics and alarms
- **Networking**: VPC with multi-AZ deployment + security groups
- **Secrets**: AWS Secrets Manager with automatic rotation

## Prerequisites

1. AWS CLI configured
2. Terraform >= 1.0
3. Domain name for SSL certificate
4. AWS Route 53 hosted zone (optional)

## Deployment

1. Configure variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Modify terraform.tfvars with your values
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Plan deployment:
   ```bash
   terraform plan
   ```

4. Apply infrastructure:
   ```bash
   terraform apply -var="domain_name=yourdomain.com" -var="db_password=YourSecurePassword123!"
   ```

   Or create a `terraform.tfvars` file:
   ```hcl
   domain_name = "yourdomain.com"
   db_password = "YourSecurePassword123!"
   region      = "us-east-1"
   ```

## Main Variables

| Variable | Description | Default |
|----------|-------------|---------|
| region | AWS region | us-east-1 |
| project_name | Project name | heroku-clone-enterprise |
| environment | Environment name | production |
| domain_name | Domain name for application | **Required** |
| db_username | Database username | paasadmin |
| db_password | Database password | **Required** |
| s3_code_bucket_name | S3 bucket name for user code | "" (auto-generated) |
| cpu_alarm_threshold | CPU threshold for CloudWatch alarms | 80 |
| memory_alarm_threshold | Memory threshold for CloudWatch alarms | 85 |
| redis_node_type | ElastiCache Redis node type | cache.t3.micro |

## Output

After deployment, you will get:
- VPC and subnet IDs (public/private)
- ECS Cluster ID and Service name
- ALB DNS name
- Aurora Serverless endpoint and port
- Redis cluster endpoint and port
- S3 bucket name (with backup bucket)
- CloudFront distribution URL
- SSL certificate ARN
- ECR repository URL

## Cleanup

```bash
terraform destroy
```

## Notes

- **ECS Fargate** provides serverless container orchestration with automatic scaling
- **Aurora Serverless v2** automatically scales database capacity based on demand
- **ElastiCache Redis** provides high-availability caching with Multi-AZ
- **CloudFront** delivers content globally with edge locations
- **S3** includes cross-region replication for disaster recovery
- **CloudWatch** monitors all resources with custom alarms and metrics
- **SSL certificates** are managed automatically via ACM
- **Secrets Manager** handles sensitive data with automatic rotation

*Costs may vary based on usage and region*
