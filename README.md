# PaaS Infrastructure – Enterprise Deployment

Enterprise-grade Platform-as-a-Service (PaaS) infrastructure with ECS Fargate + multi-region deployment, for a Heroku-like clone.

## Architecture

- **Compute**: ECS Fargate with auto-scaling containers
- **Load Balancer**: Application Load Balancer with HTTPS/SSL
- **Database**: RDS PostgreSQL Multi-AZ with cross-region backup
- **Cache**: ElastiCache Redis cluster
- **Storage**: S3 with versioning and cross-region replication
- **CDN**: CloudFront distribution for global content delivery
- **Monitoring**: CloudWatch with custom metrics and alarms
- **Networking**: VPC with multi-AZ deployment + security groups

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
   terraform apply
   ```

## Main Variables

| Variable | Description | Default |
|----------|-------------|---------|
| region | AWS region | us-east-1 |
| project_name | Project name | heroku-clone-enterprise |
| environment | Environment name | production |
| domain_name | Domain name for application | Required |
| db_username | Database username | paasadmin |
| db_password | Database password | Required |

## Output

After deployment, you will get:
- VPC and subnet IDs
- ALB DNS name
- RDS endpoint
- Redis endpoint
- S3 bucket name
- CloudFront distribution URL
- SSL certificate ARN

## Cleanup

```bash
terraform destroy
```

## Notes

- ECS Fargate provides serverless container orchestration
- Auto-scaling is handled automatically by AWS
- Cross-region backup ensures disaster recovery
- CloudWatch monitors all resources with custom alarms
- SSL certificates are managed automatically via ACM
