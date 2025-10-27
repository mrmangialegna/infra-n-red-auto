PaaS Infrastructure – Advanced Deployment

Enterprise-grade Platform-as-a-Service (PaaS) infrastructure with ECS Fargate + Aurora Serverless.

-----------------------------------------------------
Architecture

- Compute: ECS Fargate with auto-scaling containers (serverless)
- Load Balancer: Application Load Balancer with HTTPS/SSL
- Database: Aurora Serverless v2 PostgreSQL with automatic scaling
- Cache: ElastiCache Redis cluster with Multi-AZ
- Storage: S3 with versioning and cross-region replication
- CDN: CloudFront distribution for global content delivery
- Monitoring: CloudWatch with custom metrics and alarms
- Networking: VPC with multi-AZ deployment + security groups
- Secrets: AWS Secrets Manager with automatic rotation

Prerequisites

1. AWS CLI configured
2. Terraform >= 1.0
3. Domain name for SSL certificate
4. AWS Route 53 hosted zone (optional)
5. Existing EC2 key pair

-----------------------------------------------------
Pre-deployment Steps

Before applying Terraform, create the Lambda zip file:

```bash
# Install dependencies
pip install -r requirements.txt -t .

# Create webhook handler zip (includes dependencies)
zip -r webhook_handler.zip webhook_handler.py index.py boto3 psycopg2_binary-*.dist-info urllib3
```

-----------------------------------------------------
Deployment

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

-----------------------------------------------------
Main Variables

Variables

region us-east-1
project_name Clone-enterprise |
environment Production
domain_name Required
db_username paasadmin 
db_password Required
s3_code_bucket_name | S3 bucket name for user code | "" (auto-generated) |
cpu_alarm_threshold | CPU threshold for CloudWatch alarms | 80 |
memory_alarm_threshold | Memory threshold for CloudWatch alarms | 85 |
redis_node_type, lastiCache Redis node type, cache.t3.micro |

-----------------------------------------------------
Output

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

-----------------------------------------------------
Post-deployment Configuration

1. Initialize Database Schema

Connect to the Aurora Serverless cluster and run the init_db.sql script:

```bash
# Get RDS endpoint from terraform output
RDS_ENDPOINT=$(terraform output -raw aurora_endpoint)

# Connect and run init script
psql -h $RDS_ENDPOINT -U paasadmin -d paasdb -f init_db.sql
```

2. Configure GitHub Webhook

After deployment, get the API Gateway webhook URL from Terraform outputs:

```bash
WEBHOOK_URL=$(terraform output -raw webhook_url)
```

Configure this URL in your GitHub repository:
1. Go to Settings → Webhooks
2. Add webhook URL: `https://${WEBHOOK_URL}/webhook/{app_name}`
3. Set content type to `application/json`
4. Enable "Just the push event"

3. Deploy Your First App

1. Push code to your GitHub repository
2. The webhook triggers the Lambda function
3. Lambda downloads the code, uploads to S3
4. Step Functions triggers CodeBuild
5. CodeBuild builds Docker image and pushes to ECR
6. CodeBuild deploys to ECS Fargate
7. Your app is live!

-----------------------------------------------------
Cleanup

```bash
terraform destroy
```