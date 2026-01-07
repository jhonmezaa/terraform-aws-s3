# Complete S3 Module Example - All Features

This is the **reference implementation** showcasing ALL available features of the terraform-aws-s3 module.

## Features Demonstrated

### ✅ Core Features
- [x] Bucket creation with auto-naming
- [x] Versioning with MFA delete support
- [x] Server-side encryption (SSE-S3)
- [x] Public access blocking (all 4 settings)

### ✅ Lifecycle Management
- [x] Multiple lifecycle rules per bucket
- [x] Storage class transitions (5 tiers)
- [x] Noncurrent version transitions
- [x] Expiration policies
- [x] Abort incomplete multipart uploads
- [x] Prefix-based filtering
- [x] Object size filtering

### ✅ Advanced Storage
- [x] Intelligent-Tiering configurations
- [x] Transfer acceleration
- [x] Object Lock (COMPLIANCE/GOVERNANCE mode)

### ✅ Monitoring & Analytics
- [x] S3 Inventory reports
- [x] Storage class analysis
- [x] Request metrics (CloudWatch)
- [x] Access logging

### ✅ Event Notifications
- [x] EventBridge integration
- [x] Lambda function triggers
- [x] SNS topic notifications
- [x] Prefix/suffix filtering

### ✅ Access Control
- [x] Bucket policies (TLS enforcement)
- [x] Custom policies with **Placeholders** ({{BUCKET_ID}}, {{BUCKET_ARN}}, {{ACCOUNT_ID}}, {{REGION}})
- [x] Object ownership controls
- [x] Request payment configuration

### ✅ Special Features
- [x] CORS configuration (see static-website example)
- [x] Website hosting (see static-website example)
- [x] Cross-region replication (see with-replication example)
- [x] Log delivery policies (see log-delivery example)

## Buckets Created

### 1. Complete Bucket
Demonstrates maximum feature utilization:
- 3 lifecycle rules (tiered storage, temp cleanup, large files)
- Intelligent-Tiering with ARCHIVE_ACCESS
- S3 Inventory (weekly, ORC format)
- Storage class analysis
- Request metrics (2 configs)
- Event notifications (Lambda + SNS + EventBridge)
- Transfer acceleration
- Full observability

### 2. Compliance Bucket
Demonstrates Object Lock:
- COMPLIANCE mode retention (30 days)
- Versioning required
- Write-once-read-many (WORM) storage
- Immutable objects

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Outputs

All comprehensive outputs available:
```bash
terraform output buckets_summary
terraform output complete_bucket_features
terraform output compliance_bucket_features
```

## Feature Matrix

| Feature Category | Features Enabled | Configuration File |
|-----------------|------------------|-------------------|
| **Core** | 4/4 | `1-bucket.tf`, `2-versioning.tf`, `3-encryption.tf` |
| **Lifecycle** | All | `4-lifecycle.tf` |
| **Policies** | TLS + Custom | `6-bucket-policy.tf` |
| **Monitoring** | Inventory, Analytics, Metrics | `14-inventory.tf`, `15-analytics.tf`, `16-metrics.tf` |
| **Notifications** | Lambda, SNS, EventBridge | `17-notifications.tf` |
| **Advanced** | Intelligent-Tiering, Acceleration, Object Lock | `13-intelligent-tiering.tf`, `10-acceleration.tf`, `12-object-lock.tf` |

## Cost Estimate (Monthly)

Assuming 1 TB storage, 1M requests:

| Feature | Cost | Notes |
|---------|------|-------|
| Storage (STANDARD) | $23.00 | Base cost |
| Requests (GET/PUT) | $0.40 | API calls |
| Versioning | ~$5.00 | Previous versions |
| Lifecycle transitions | ~$0.10 | Per 1000 transitions |
| Intelligent-Tiering | ~$0.25 | Monitoring/automation |
| Inventory | ~$2.50 | Weekly reports |
| Analytics | $0.10 | Storage class analysis |
| Transfer Acceleration | Variable | Only when used |
| **TOTAL** | **~$31.35** | Excludes data transfer |

## Testing

### Test Lifecycle Rules
```bash
BUCKET=$(terraform output -json all_bucket_ids | jq -r '.complete')

# Upload test files
aws s3 cp test.txt s3://$BUCKET/test.txt
aws s3 cp large.bin s3://$BUCKET/large.bin
aws s3 cp temp.txt s3://$BUCKET/temp/temp.txt

# Check lifecycle configuration
aws s3api get-bucket-lifecycle-configuration --bucket $BUCKET
```

### Test Acceleration
```bash
# Upload via accelerated endpoint
aws s3 cp large-file.bin s3://$BUCKET/large-file.bin \
  --endpoint-url https://s3-accelerate.amazonaws.com
```

### Test Notifications
```bash
# Trigger Lambda notification
aws s3 cp upload.txt s3://$BUCKET/uploads/upload.txt

# Check CloudWatch Logs for Lambda execution
aws logs tail /aws/lambda/process-s3-upload --follow
```

### Test Object Lock
```bash
COMPLIANCE_BUCKET=$(terraform output -json all_bucket_ids | jq -r '.compliance')

# Upload object with lock
aws s3 cp protected.txt s3://$COMPLIANCE_BUCKET/protected.txt

# Try to delete (should fail due to COMPLIANCE mode)
aws s3 rm s3://$COMPLIANCE_BUCKET/protected.txt
# Error: Access Denied
```

## Production Considerations

Before using in production:

1. **Remove `force_destroy = true`**: Prevent accidental deletion
2. **Review retention periods**: Adjust for compliance needs
3. **Configure actual notification targets**: Replace placeholder ARNs
4. **Set up destination buckets**: For inventory/analytics/logging
5. **Enable MFA delete**: For critical buckets
6. **Configure backup**: Consider AWS Backup integration
7. **Review costs**: Enable Cost Allocation Tags

## Important Implementation Notes

### Policy Placeholders

The complete bucket demonstrates **policy placeholders** - a feature that simplifies custom bucket policies:

```hcl
custom_policy_statements = jsonencode({
  Statement = [{
    Principal = {
      AWS = "arn:aws:iam::{{ACCOUNT_ID}}:root"
    }
    Resource = "{{BUCKET_ARN}}/*"
  }]
})
```

Placeholders are automatically replaced at apply time:
- `{{BUCKET_ID}}` → Actual bucket name
- `{{BUCKET_ARN}}` → Bucket ARN
- `{{ACCOUNT_ID}}` → AWS Account ID
- `{{REGION}}` → AWS Region

This eliminates the need to manually calculate bucket names in locals.

### Notification Filters (Critical)

**Each notification rule MUST have non-overlapping filters** to avoid errors:

❌ **Bad - Will fail:**
```hcl
notifications = {
  lambda_functions = {
    handler1 = {
      events = ["s3:ObjectCreated:*"]
      filter_prefix = "data/"
    }
  }
  sns_topics = {
    alerts = {
      events = ["s3:ObjectCreated:*"]
      # No prefix - overlaps with everything!
    }
  }
}
```

✅ **Good - Non-overlapping:**
```hcl
notifications = {
  lambda_functions = {
    handler1 = {
      events = ["s3:ObjectCreated:*"]
      filter_prefix = "uploads/"
      filter_suffix = ".jpg"
    }
  }
  sns_topics = {
    alerts = {
      events = ["s3:ObjectRemoved:*"]
      filter_prefix = "archived/"
    }
  }
}
```

AWS will reject configurations with ambiguous/overlapping notification rules.

### Replication Limitations

This example does **not** include replication because:
- Replication Schema V2 (advanced features) is not universally supported
- Schema V1 (basic) only supports single rule without priority
- See [with-replication](../with-replication/) example for working implementation

## Cleanup

```bash
# Empty buckets (required due to versioning/object lock)
./empty-buckets.sh

# Destroy
terraform destroy
```

## Next Steps

- Review other examples for specific use cases
- Customize lifecycle rules for your data patterns
- Integrate with your CI/CD pipeline
- Set up CloudWatch alarms for monitoring
- Configure backup automation

## Documentation References

- [S3 Lifecycle Configuration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
- [S3 Intelligent-Tiering](https://aws.amazon.com/s3/storage-classes/intelligent-tiering/)
- [S3 Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)
- [S3 Inventory](https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-inventory.html)
- [S3 Event Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html)
