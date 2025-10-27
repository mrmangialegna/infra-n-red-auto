import json
import boto3
import urllib.request
import tempfile
import os
import uuid
import hashlib

s3 = boto3.client('s3')
sf = boto3.client('states')
elbv2 = boto3.client('elbv2')
ecs = boto3.client('ecs')

def handler(event, context):
    try:
        # Get environment variables
        bucket_name = os.environ['CODE_BUCKET']
        postgres_host = os.environ['POSTGRES_HOST']
        postgres_db = os.environ['POSTGRES_DB']
        postgres_user = os.environ['POSTGRES_USER']
        postgres_pass = os.environ['POSTGRES_PASS']
        step_function_arn = os.environ['STEP_FUNCTION_ARN']
        cluster_name = os.environ['ECS_CLUSTER_NAME']
        lb_arn = os.environ['ALB_ARN']
        listener_arn = os.environ['LISTENER_ARN']
        vpc_id = os.environ['VPC_ID']
        
        # Parse webhook payload
        body = json.loads(event['body'])
        app_name = event['pathParameters']['app_name']
        
        # Validate GitHub webhook signature
        github_secret = os.environ.get('GITHUB_WEBHOOK_SECRET')
        if github_secret and not validate_webhook_signature(event, github_secret):
            return {
                'statusCode': 401,
                'body': json.dumps({'error': 'Unauthorized webhook'})
            }
        
        # GitHub webhook
        if 'repository' in body and 'head_commit' in body:
            repo_url = body['repository']['clone_url']
            commit_sha = body['head_commit']['id']
            
            # Download repository as zip
            zip_url = f"{repo_url.replace('.git', '')}/archive/{commit_sha}.zip"
            
            with tempfile.NamedTemporaryFile() as tmp_file:
                urllib.request.urlretrieve(zip_url, tmp_file.name)
                
                # Upload to S3 with tenant isolation
                s3_key = f"tenants/{app_name}/{commit_sha}.zip"
                s3.upload_file(tmp_file.name, bucket_name, s3_key)
            
            # Update app metadata in PostgreSQL
            import psycopg2
            
            conn = psycopg2.connect(
                host=postgres_host,
                database=postgres_db,
                user=postgres_user,
                password=postgres_pass
            )
            
            with conn.cursor() as cur:
                # Check if app exists or create new
                cur.execute("""
                    INSERT INTO platform.deployments (app_name, repo_url, commit_sha, status, created_at)
                    VALUES (%s, %s, %s, 'building', NOW())
                    ON CONFLICT (app_name) DO UPDATE SET
                    commit_sha = EXCLUDED.commit_sha,
                    status = 'building',
                    updated_at = NOW()
                """, (app_name, repo_url, commit_sha))
                
                # Get app config
                cur.execute("""
                    SELECT COALESCE(env_vars, '{}'::jsonb) as env_vars,
                           COALESCE(scaling, '{"replicas": 2}'::jsonb) as scaling
                    FROM platform.app_configs
                    WHERE app_name = %s
                """, (app_name,))
                
                config = cur.fetchone()
                env_vars = config[0] if config else {}
                scaling = config[1] if config else {'replicas': 2}
                
            conn.commit()
            
            # Create or update ECS service for this app/tenant
            create_ecs_service_for_app(
                cluster_name, app_name, lb_arn, listener_arn, 
                vpc_id, env_vars, scaling
            )
            
            conn.close()
            
            # Trigger Step Functions execution with app context
            sf.start_execution(
                stateMachineArn=step_function_arn,
                input=json.dumps({
                    'app_name': app_name,
                    'commit_sha': commit_sha,
                    'repo_url': repo_url,
                    's3_key': s3_key
                })
            )
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': f'Deployment triggered for {app_name}',
                    'commit': commit_sha,
                    'app_name': app_name
                })
            }
        
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Invalid webhook payload'})
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def create_ecs_service_for_app(cluster_name, app_name, lb_arn, listener_arn, vpc_id, env_vars, scaling):
    """Create dynamic ECS service for multi-tenant app"""
    
    # Create target group for this app
    target_group = elbv2.create_target_group(
        Name=f"{app_name}-tg-{hashlib.md5(app_name.encode()).hexdigest()[:8]}",
        Protocol='HTTP',
        Port=80,
        VpcId=vpc_id,
        TargetType='ip',
        HealthCheckPath='/health',
        HealthCheckProtocol='HTTP',
        HealthCheckIntervalSeconds=30,
        HealthCheckTimeoutSeconds=5,
        HealthyThresholdCount=2,
        UnhealthyThresholdCount=2
    )['TargetGroups'][0]
    
    # Create listener rule for host-based routing
    priority = generate_unique_priority()
    
    elbv2.create_rule(
        ListenerArn=listener_arn,
        Priority=priority,
        Conditions=[
            {
                'Field': 'host-header',
                'HostHeaderConfig': {
                    'Values': [f"{app_name}.{os.environ.get('DOMAIN_NAME', 'example.com')}"]
                }
            }
        ],
        Actions=[
            {
                'Type': 'forward',
                'ForwardConfig': {
                    'TargetGroups': [
                        {
                            'TargetGroupArn': target_group['TargetGroupArn']
                        }
                    ]
                }
            }
        ]
    )
    
    # Create or update ECS service
    try:
        ecs.describe_services(cluster=cluster_name, services=[f"{app_name}-service"])
        # Service exists, update it
        ecs.update_service(
            cluster=cluster_name,
            service=f"{app_name}-service",
            desiredCount=scaling.get('replicas', 2)
        )
    except:
        # Service doesn't exist, will be created by CodeBuild
        pass
    
    return target_group['TargetGroupArn']

def generate_unique_priority():
    """Generate unique priority for ALB listener rules"""
    import time
    return int(time.time() * 1000) % 50000  # Ensure priority is under 50000

def validate_webhook_signature(event, secret):
    """Validate GitHub webhook signature"""
    import hmac
    
    headers = event.get('headers', {})
    signature = headers.get('X-Hub-Signature-256', '')
    
    if not signature:
        return False
    
    # GitHub sends sha256=xxx
    signature = signature.replace('sha256=', '')
    
    # Get request body
    body = event.get('body', '')
    if isinstance(body, str):
        body = body.encode('utf-8')
    
    # Create HMAC signature
    expected = hmac.new(
        secret.encode('utf-8'),
        body,
        hashlib.sha256
    ).hexdigest()
    
    # Constant time comparison
    return hmac.compare_digest(signature, expected)

