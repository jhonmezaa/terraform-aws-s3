# S3 Cross-Region Replication Example

Demonstrates automatic cross-region replication for disaster recovery and compliance using a single replication rule (S3 Replication Schema V1).

## Features

- **Cross-Region Replication (CRR)**: us-east-1 → us-west-2
- **Single Replication Rule**: All objects replicated
- **Storage Class**: STANDARD (configurable)
- **Versioning**: Required on both source and destination
- **IAM Role**: Automatic setup with proper permissions
- **Encryption**: SSE-S3 enabled on both buckets

## Schema V1 vs Schema V2

AWS S3 has two replication configuration schemas. Since v2.2.0 the module selects the schema **per rule**:

| Rule settings | Schema | What the module sends |
| --- | --- | --- |
| No `filter_prefix`/`filter_tags` and `delete_marker_replication_enabled = false` | V1 | No `filter`, no `priority`, no `delete_marker_replication` |
| `filter_prefix` or `filter_tags` set, or `delete_marker_replication_enabled = true` | V2 | `filter` (empty if no criteria), `priority`, `delete_marker_replication` |

The previous "Schema V2 is not available" errors (`Priority cannot be used for this version...`) happen when `priority`/`delete_marker_replication` are sent **without** a `filter` block. AWS requires `DeleteMarkerReplication` whenever a `Filter` is present, so the module now sends both together.

This example uses a single V1 rule (no filter).

## Architecture

```
┌─────────────────┐           ┌─────────────────┐
│   us-east-1     │           │   us-west-2     │
│                 │           │                 │
│  Source Bucket  │ ────────> │ Replica Bucket  │
│  (ause1-...)    │ Replicate │  (usw2-...)     │
│                 │           │                 │
│  Versioning: ✓  │           │  Versioning: ✓  │
│  Encryption: ✓  │           │  Encryption: ✓  │
└─────────────────┘           └─────────────────┘
         │
         ├─ IAM Replication Role
         │  • GetObject permissions
         │  • ReplicateObject permissions
         └─ S3 assumes this role
```

## Usage

1. **Copy example variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars:**
   ```hcl
   primary_region = "us-east-1"
   replica_region = "us-west-2"
   account_name   = "prod"
   project_name   = "myapp"
   ```

3. **Deploy infrastructure:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Test replication:**
   ```bash
   # Upload a test file to source bucket
   echo "Hello World" > test.txt
   aws s3 cp test.txt s3://$(terraform output -raw primary_bucket_id)/

   # Wait a few seconds for replication
   sleep 10

   # Verify file was replicated to destination
   aws s3 ls s3://$(terraform output -raw replica_bucket_id)/

   # Download from replica to verify content
   aws s3 cp s3://$(terraform output -raw replica_bucket_id)/test.txt test-replica.txt
   cat test-replica.txt
   ```

## Replication Rule

**replicate_all**: Replicates all objects
- Source: All objects in source bucket
- Destination: Replica bucket in secondary region
- Storage Class: STANDARD (same as source)
- Filter: None (all objects)

## Requirements

Both buckets must have:
- ✅ Versioning enabled
- ✅ Same encryption type (SSE-S3 in this example)
- ✅ IAM role with proper permissions

## Cost Considerations

**Replication Costs:**
- Data transfer: ~$0.02 per GB (cross-region)
- Storage: Standard rates in both regions
- Requests: PUT/GET charges apply

**Example monthly cost for 100GB:**
- Source storage: $2.30 (us-east-1)
- Replica storage: $2.30 (us-west-2)
- Data transfer: $2.00
- **Total: ~$6.60/month**

**Cost Optimization:**
- Use lifecycle rules on replica bucket to transition old versions to cheaper storage
- Consider Same-Region Replication (SRR) if disaster recovery across regions isn't required (~50% cheaper)
- Filter by prefix if you only need to replicate specific paths

## Outputs

- `primary_bucket_id` - Source bucket name
- `primary_bucket_arn` - Source bucket ARN
- `replica_bucket_id` - Destination bucket name
- `replica_bucket_arn` - Destination bucket ARN
- `replication_role_arn` - IAM role ARN for replication

## Multiple rules / advanced features

To use several rules, delete marker replication, metrics or Replication Time Control, give each rule a filter (or set `delete_marker_replication_enabled = true`) and a **unique** `priority`. RTC requires `metrics_enabled = true`.

## Cleanup

⚠️ **Important:** Destroy replica bucket first to avoid replication errors during teardown.

```bash
# Option 1: Destroy all
terraform destroy

# Option 2: Manual cleanup (if needed)
aws s3 rb s3://$(terraform output -raw replica_bucket_id) --force
aws s3 rb s3://$(terraform output -raw primary_bucket_id) --force
terraform destroy
```

## Troubleshooting

### Replication not working?

1. **Check versioning is enabled:**
   ```bash
   aws s3api get-bucket-versioning --bucket <bucket-name>
   ```

2. **Verify IAM role permissions:**
   ```bash
   aws iam get-role-policy --role-name <role-name> --policy-name <policy-name>
   ```

3. **Check replication configuration:**
   ```bash
   aws s3api get-bucket-replication --bucket <source-bucket>
   ```

4. **View replication status:**
   ```bash
   aws s3api head-object --bucket <source-bucket> --key <object-key> --version-id <version-id>
   # Look for: "ReplicationStatus": "COMPLETED"
   ```

### Common Errors

**Error: Priority cannot be used / DeleteMarkerReplication cannot be used**
- Cause: V2 attributes sent without a `filter` block (module versions < v2.2.0)
- Solution: Upgrade to v2.2.0+; the module sends them only together with a filter

**Error: ReplicationConfigurationNotFoundError**
- Cause: Replication config not applied yet
- Solution: Run terraform apply again

## Related Examples

- [simple](../simple/) - Basic bucket setup
- [with-versioning](../with-versioning/) - Advanced versioning and lifecycle
- [log-delivery](../log-delivery/) - Log buckets with proper policies
