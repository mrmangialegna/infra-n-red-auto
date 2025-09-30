# monitoring.tf

# -------------------------
# CloudWatch EC2 CPU Alarm
# -------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "paas-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "Alarm if EC2 CPU > ${var.cpu_alarm_threshold}%"

  alarm_actions = []
}

# -------------------------
# CloudWatch EC2 Status Check Alarm
# -------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  alarm_name          = "paas-ec2-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Alarm if EC2 status check fails"

  alarm_actions = []
}

# -------------------------
# CloudWatch RDS CPU Alarm
# -------------------------
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "paas-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "Alarm if RDS CPU > ${var.cpu_alarm_threshold}%"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  alarm_actions = []
}

# -------------------------
# CloudWatch Redis CPU Alarm
# -------------------------
resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  alarm_name          = "paas-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "Alarm if Redis CPU > ${var.cpu_alarm_threshold}%"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.id
  }

  alarm_actions = []
}

# -------------------------
# CloudWatch Custom Metrics from Kubernetes
# -------------------------
resource "aws_cloudwatch_metric_alarm" "k8s_node_memory_high" {
  alarm_name          = "paas-k8s-node-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold
  alarm_description   = "Alarm if K8s node memory > ${var.memory_alarm_threshold}%"

  alarm_actions = []
}
