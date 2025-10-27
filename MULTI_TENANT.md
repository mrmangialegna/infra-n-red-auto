# Multi-Tenant PaaS Architecture

## Features Implemented

### 1. Multi-Tenancy (✅ Complete)
- **Dynamic ECS Services**: Each tenant/app gets its own ECS service
- **Dynamic Target Groups**: ALB target groups created per-tenant for isolation
- **Isolated Resources**: S3 paths like `tenants/{app_name}/{commit_sha}.zip`

### 2. ALB Routing (✅ Complete)
- **Host-based Routing**: `{app_name}.domain.com` routes to specific app
- **Dynamic Listener Rules**: Created programmatically via Lambda
- **Priority Management**: Unique priority per rule to avoid conflicts

### 3. Webhook Security (✅ Complete)
- **AWS_IAM Authorization**: API Gateway requires AWS IAM authentication
- **HMAC SHA256 Validation**: Validates GitHub webhook signatures
- **Secret Management**: GitHub webhook secret stored in Lambda environment

### 4. Database Isolation (✅ Complete)
- **Tenant-aware Tables**: app_name as primary key in deployments
- **Isolated Queries**: All DB operations scoped to app_name
- **Concurrency Safe**: ON CONFLICT UPDATE for safe concurrent deployments

## How It Works

1. **GitHub Push** → Webhook with AWS IAM auth
2. **Lambda Validates** → HMAC signature + IAM credentials
3. **Creates Resources** → Target Group + Listener Rule + ECS Service
4. **CodeBuild** → Builds Docker image
5. **Deploys to ECS** → Isolated per-tenant service
6. **ALB Routes** → Host-based routing to correct service

## Usage Example

```bash
# Deploy app "myapp"
git push origin main  # Triggers webhook

# App accessible at:
https://myapp.yourdomain.com

# Deploy another app "otherapp"
git push origin main  # Triggers webhook

# Both apps running, isolated:
https://myapp.yourdomain.com      → myapp ECS service
https://otherapp.yourdomain.com   → otherapp ECS service
```

## Security Considerations

- ✅ AWS IAM authentication required for webhooks
- ✅ GitHub signature validation prevents unauthorized deployments
- ✅ Tenant isolation in S3, ECS, and ALB
- ✅ Database isolation per app_name
- ⚠️  GitHub secret should be stored in AWS Secrets Manager (TODO)

## Next Steps

1. Store GitHub secret in Secrets Manager instead of Lambda env vars
2. Add rate limiting per tenant
3. Add tenant quotas (CPU/memory limits)
4. Implement tenant-level IAM policies

