# S3 Log Delivery Buckets Example

Demonstrates S3 buckets configured to receive logs from various AWS services with appropriate policies and lifecycle management.

## Buckets Created

### 1. ELB/ALB/NLB Logs (`elb-logs`)
- **Policy**: ELB service account write access
- **Retention**: 90 days
- **Lifecycle**: STANDARD → STANDARD_IA (30 days) → Expire
- **Use Case**: Load balancer access logs

### 2. CloudTrail Logs (`cloudtrail-logs`)
- **Policy**: CloudTrail service write access
- **Retention**: 7 years (compliance)
- **Lifecycle**: STANDARD → STANDARD_IA (90d) → GLACIER (1yr) → Expire (7yr)
- **Versioning**: Enabled for audit integrity
- **Use Case**: API audit logs

### 3. WAF Logs (`waf-logs`)
- **Policy**: WAF logging service write access
- **Retention**: 30 days
- **Lifecycle**: Expire after 30 days
- **Use Case**: Web Application Firewall logs

### 4. Application Logs (`app-logs`)
- **Policy**: TLS enforcement + Custom cross-account policy (using placeholders)
- **Retention**: 1 year
- **Lifecycle**: STANDARD → STANDARD_IA (7d) → GLACIER (30d) → Expire (1yr)
- **Notifications**: Lambda trigger for ERROR logs (commented out - requires Lambda to exist)
- **Placeholders**: Demonstrates automatic replacement of {{BUCKET_ID}}, {{BUCKET_ARN}}, {{ACCOUNT_ID}}, {{REGION}}
- **Use Case**: Custom application logging with cross-account access

## Usage

```bash
terraform init
terraform apply
```

### Configure AWS Services

#### ELB/ALB
```hcl
resource "aws_lb" "main" {
  # ...

  access_logs {
    bucket  = module.s3_buckets.bucket_ids["elb-logs"]
    prefix  = "alb"
    enabled = true
  }
}
```

#### CloudTrail
```hcl
resource "aws_cloudtrail" "main" {
  name           = "main-trail"
  s3_bucket_name = module.s3_buckets.bucket_ids["cloudtrail-logs"]
}
```

#### WAF
```hcl
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = [module.s3_buckets.bucket_arns["waf-logs"]]
}
```

## Policy Placeholders Feature

The `app-logs` bucket demonstrates the **placeholder system** for custom bucket policies. Instead of manually calculating bucket names and ARNs, you can use placeholders that are automatically replaced:

### Available Placeholders

| Placeholder | Replaced With | Example |
|-------------|---------------|---------|
| `{{BUCKET_ID}}` | Bucket name | `ause1-s3-prod-myapp-app-logs` |
| `{{BUCKET_ARN}}` | Bucket ARN | `arn:aws:s3:::ause1-s3-prod-myapp-app-logs` |
| `{{ACCOUNT_ID}}` | AWS Account ID | `123456789012` |
| `{{REGION}}` | AWS Region | `us-east-1` |

### Example Usage

```hcl
custom_policy_statements = jsonencode({
  Version = "2012-10-17"
  Statement = [{
    Effect = "Allow"
    Principal = {
      AWS = "arn:aws:iam::{{ACCOUNT_ID}}:root"
    }
    Action = "s3:GetObject"
    Resource = "{{BUCKET_ARN}}/*"
  }]
})
```

The module automatically replaces placeholders at apply time, eliminating the need for complex local value calculations.

## Compliance Features

- ✅ **Encryption**: All buckets encrypted (SSE-S3)
- ✅ **Access Control**: Service-specific IAM policies
- ✅ **Retention Policies**: Configurable per log type
- ✅ **Versioning**: Enabled for audit logs (CloudTrail)
- ✅ **Cost Optimization**: Automatic tiering to cheaper storage

## Cost Considerations

| Log Type | Volume (Est.) | Monthly Cost (Est.) |
|----------|---------------|---------------------|
| ELB | 100 GB/month | ~$2.30 (STANDARD) |
| CloudTrail | 50 GB/month | ~$0.18 (GLACIER after 1yr) |
| WAF | 200 GB/month | ~$4.60 (30-day retention) |
| App Logs | 500 GB/month | ~$5.75 (tiered storage) |

## Cleanup

```bash
terraform destroy
```
