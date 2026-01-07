# S3 Bucket with Advanced Versioning and Lifecycle Example

This example demonstrates advanced versioning and lifecycle management for cost optimization and data retention compliance.

## Features Demonstrated

### Versioning
- **Enabled on all buckets**: Protects against accidental deletion
- **Noncurrent version management**: Automatic cleanup of old versions
- **Version retention policies**: Keep N newest versions

### Lifecycle Rules

#### Data Bucket (3 rules)
1. **archive_old_data**: Multi-tier storage transitions
   - Day 30: → STANDARD_IA (Infrequent Access)
   - Day 90: → GLACIER_IR (Instant Retrieval)
   - Day 180: → GLACIER
   - Day 365: → DEEP_ARCHIVE
   - Noncurrent versions: Expire after 180 days, keep 3 newest

2. **expire_temp_files**: Quick expiration for temporary data
   - Prefix filter: `temp/`
   - Expire after 7 days
   - Noncurrent versions expire after 1 day

3. **archive_large_logs**: Size-based filtering
   - Prefix filter: `logs/`
   - Size filter: > 1 MB
   - Archive to GLACIER after 7 days
   - Expire after 90 days

#### Backups Bucket (1 rule)
1. **retain_backups**: Long-term retention
   - Archive to GLACIER after 1 year
   - Retain for 7 years total
   - Keep 10 previous versions

### Cost Optimization Features
- ✅ Automatic storage class transitions
- ✅ Noncurrent version expiration
- ✅ Abort incomplete multipart uploads
- ✅ Prefix-based rules for different data types
- ✅ Size-based filtering

## Storage Class Cost Comparison

| Storage Class | Cost (per GB/month) | Retrieval Time | Use Case |
|--------------|---------------------|----------------|----------|
| STANDARD | $0.023 | Instant | Active data |
| STANDARD_IA | $0.0125 | Instant | Infrequent access |
| GLACIER_IR | $0.004 | Instant | Archive with instant retrieval |
| GLACIER | $0.0036 | Minutes-Hours | Long-term archive |
| DEEP_ARCHIVE | $0.00099 | 12 hours | Rarely accessed |

## Usage

1. Copy and customize variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Apply the configuration:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. Test lifecycle transitions:
   ```bash
   # Upload a test file to the data bucket
   aws s3 cp test.txt s3://$(terraform output -raw bucket_ids | jq -r '.data')/test.txt

   # Upload a temporary file
   aws s3 cp temp.txt s3://$(terraform output -raw bucket_ids | jq -r '.data')/temp/temp.txt

   # Check lifecycle rules are applied
   aws s3api get-bucket-lifecycle-configuration \
     --bucket $(terraform output -raw bucket_ids | jq -r '.data')
   ```

## Lifecycle Rule Logic

### Transitions
Objects automatically move through storage classes based on age:
```
STANDARD → STANDARD_IA → GLACIER_IR → GLACIER → DEEP_ARCHIVE
```

### Noncurrent Versions
When an object is updated:
- Previous version becomes "noncurrent"
- Noncurrent versions follow separate lifecycle rules
- Can keep N newest noncurrent versions

### Prefix Filtering
Apply different rules to different paths:
- `/temp/` - Expire quickly (7 days)
- `/logs/` - Archive and expire (90 days)
- Everything else - Full tiering (365 days)

## Best Practices Implemented

1. **Multipart Upload Cleanup**: Abort incomplete uploads after 3-7 days
2. **Version Management**: Keep limited number of old versions
3. **Cost Optimization**: Transition to cheaper storage as data ages
4. **Compliance**: Retention policies for regulatory requirements
5. **Data Classification**: Different rules for different data types

## Cleanup

```bash
terraform destroy
```

Note: With versioning enabled, all versions must be deleted before bucket deletion. `force_destroy = true` handles this automatically.
