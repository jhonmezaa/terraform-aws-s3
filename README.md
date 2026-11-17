# Terraform AWS S3 Module

Production-ready Terraform module for creating and managing AWS S3 buckets with 22+ advanced features.

## Features

### Core Features

- ✅ **Bucket Management**: Auto-naming with region prefix detection
- ✅ **Versioning**: With MFA delete support
- ✅ **Encryption**: SSE-S3 (AES256) and SSE-KMS with bucket keys
- ✅ **Public Access Block**: All 4 independent settings

### Lifecycle Management

- ✅ **Advanced Lifecycle Rules**: Multiple rules per bucket
- ✅ **Storage Class Transitions**: STANDARD → STANDARD_IA → GLACIER_IR → GLACIER → DEEP_ARCHIVE
- ✅ **Noncurrent Version Management**: Automatic cleanup of old versions
- ✅ **Expiration Policies**: Current and noncurrent versions
- ✅ **Multipart Upload Cleanup**: Abort incomplete uploads
- ✅ **Advanced Filtering**: Prefix, tags, object size (greater/less than)

### Access & Security

- ✅ **Bucket Policies**: TLS enforcement, TLS 1.2+, upload-encryption guardrails, ELB/NLB/S3 access log/CloudTrail/WAF log delivery
- ✅ **Custom Policies with Placeholders**: Auto-replacement of {{BUCKET_ID}}, {{BUCKET_ARN}}, {{ACCOUNT_ID}}, {{REGION}}
- ✅ **Object Ownership Controls**: BucketOwnerEnforced, BucketOwnerPreferred, ObjectWriter
- ✅ **ACL Support**: Canned ACLs when needed
- ✅ **Request Payment**: Requester pays option

### Website & CORS

- ✅ **Static Website Hosting**: Index/error documents, redirects, routing rules
- ✅ **CORS Configuration**: Multiple rules with origin/method filtering

### Logging & Monitoring

- ✅ **Access Logging**: Server access logs
- ✅ **Request Metrics**: CloudWatch metrics with filtering
- ✅ **Analytics**: Storage class analysis
- ✅ **Inventory**: Scheduled inventory reports (CSV/ORC/Parquet)

### Advanced Features

- ✅ **Cross-Region Replication**: Schema V1 or V2 selected per rule (filters, priority, delete markers, cross-account, KMS replicas, metrics, RTC)
- ✅ **Transfer Acceleration**: CloudFront edge location optimization
- ✅ **Object Lock**: COMPLIANCE and GOVERNANCE modes
- ✅ **Intelligent-Tiering**: Automatic cost optimization
- ✅ **Event Notifications**: SNS, SQS, Lambda, EventBridge integration (with filter validation)

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.3  |
| aws       | >= 6.0  |

## Quick Start

```hcl
module "s3_buckets" {
  source = "git::https://github.com/jhonmezaa/terraform-aws-s3.git//s3?ref=v2.2.0"

  create       = true
  account_name = "prod"
  project_name = "myapp"

  buckets = {
    data = {
      # Security defaults are automatically applied:
      # - Encryption enabled (SSE-S3)
      # - Versioning enabled
      # - Public access blocked
      # - TLS enforcement policy

      force_destroy = false # Set to true only for non-production

      tags = {
        Environment = "production"
      }
    }
  }

  tags_common = {
    Environment = "production"
  }
}
```

## Usage Examples

### Basic Bucket with Defaults

```hcl
buckets = {
  basic = {
    # All security defaults enabled automatically
  }
}
```

### Bucket with Advanced Lifecycle

```hcl
buckets = {
  archive = {
    lifecycle_rules = {
      tiered_storage = {
        enabled = true

        transitions = [
          { days = 30, storage_class = "STANDARD_IA" },
          { days = 90, storage_class = "GLACIER_IR" },
          { days = 180, storage_class = "GLACIER" },
          { days = 365, storage_class = "DEEP_ARCHIVE" }
        ]

        expiration_days = 2555 # 7 years
        noncurrent_version_expiration_days = 90
        abort_incomplete_multipart_upload_days = 7
      }
    }
  }
}
```

### Static Website Hosting

```hcl
buckets = {
  website = {
    enable_website = true
    website_config = {
      index_document = "index.html"
      error_document = "error.html"
    }

    cors_rules = [{
      allowed_origins = ["https://example.com"]
      allowed_methods = ["GET", "HEAD"]
      allowed_headers = ["*"]
      max_age_seconds = 3000
    }]

    # Allow public reads for website
    enable_public_access_block = true
    public_access_block_config = {
      block_public_acls       = true
      block_public_policy     = false
      ignore_public_acls      = true
      restrict_public_buckets = false
    }
  }
}
```

### Log Delivery Buckets

```hcl
buckets = {
  elb-logs = {
    attach_elb_log_policy = true

    lifecycle_rules = {
      expire_logs = {
        enabled         = true
        expiration_days = 90
        transitions = [
          { days = 30, storage_class = "STANDARD_IA" }
        ]
      }
    }
  }

  cloudtrail-logs = {
    attach_cloudtrail_policy = true
    enable_versioning        = true # Recommended for audit logs
  }

  waf-logs = {
    attach_waf_log_policy = true
  }
}
```

### Cross-Region Replication

```hcl
buckets = {
  source = {
    enable_versioning  = true # Required for replication
    enable_replication = true

    replication_config = {
      role_arn = aws_iam_role.replication.arn

      rules = {
        replicate_all = {
          enabled                = true
          priority               = 1
          destination_bucket     = module.replica_bucket.bucket_arns["dest"]
          destination_storage_class = "STANDARD"

          # Enable RTC for 15-minute SLA
          replication_time_enabled = true
          replication_time_minutes = 15

          delete_marker_replication_enabled = true
        }
      }
    }
  }
}
```

## Complete Examples

Comprehensive examples are available in the [`examples/`](./examples/) directory:

1. **[simple](./examples/simple/)** - Basic bucket with security defaults
2. **[with-versioning](./examples/with-versioning/)** - Advanced lifecycle management
3. **[static-website](./examples/static-website/)** - Website hosting with CORS
4. **[with-replication](./examples/with-replication/)** - Cross-region replication
5. **[log-delivery](./examples/log-delivery/)** - ELB/CloudTrail/WAF log buckets
6. **[complete](./examples/complete/)** - ALL features enabled (reference implementation)

See the [examples README](./examples/README.md) for detailed comparison and validation instructions.

## Important Implementation Notes

### Policy Placeholders

The module supports **automatic placeholder replacement** in custom bucket policies, eliminating the need to manually calculate bucket names and ARNs:

```hcl
buckets = {
  app-logs = {
    custom_policy_statements = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Principal = {
          AWS = "arn:aws:iam::{{ACCOUNT_ID}}:root"
        }
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "{{BUCKET_ARN}}",
          "{{BUCKET_ARN}}/*"
        ]
      }]
    })
  }
}
```

**Available placeholders:**

- `{{BUCKET_ID}}` → Actual bucket name (e.g., `ause1-s3-prod-myapp-app-logs`)
- `{{BUCKET_ARN}}` → Bucket ARN (e.g., `arn:aws:s3:::ause1-s3-prod-myapp-app-logs`)
- `{{ACCOUNT_ID}}` → AWS Account ID (e.g., `123456789012`)
- `{{REGION}}` → AWS Region (e.g., `us-east-1`)

Placeholders are replaced at apply time automatically. See [log-delivery example](./examples/log-delivery/) for complete implementation.

### Replication Schema (V1 / V2)

The module selects the S3 replication schema **per rule**:

| Rule settings | Schema | Sent to AWS |
| --- | --- | --- |
| No `filter_prefix`/`filter_tags` and `delete_marker_replication_enabled = false` | V1 | no `filter`, no `priority`, no `delete_marker_replication` |
| `filter_prefix` or `filter_tags` set, or `delete_marker_replication_enabled = true` | V2 | `filter` (empty if no criteria), `priority`, `delete_marker_replication` |

AWS requires `DeleteMarkerReplication` whenever a `Filter` is present, and rejects `Priority`/`DeleteMarkerReplication` without a `Filter`; the module now sends them together. With several V2 rules, set a **unique** `priority` on each one. Replication Time Control requires `metrics_enabled = true`.

Per-rule destination options: `destination_storage_class`, `destination_account_id`, `destination_access_control_translation = { owner = "Destination" }`, `destination_replica_kms_key_id` (combine with `source_selection_criteria_sse_kms_encrypted_objects = true`).

```hcl
buckets = {
  source = {
    enable_replication = true
    replication_config = {
      role_arn = aws_iam_role.replication.arn
      rules = {
        documents = {
          priority                          = 1
          filter_prefix                     = "documents/"
          delete_marker_replication_enabled = true
          destination_bucket                = "arn:aws:s3:::destination-bucket"
          destination_storage_class         = "STANDARD_IA"
        }
      }
    }
  }
}
```

See [with-replication example](./examples/with-replication/) for a working implementation.

### Event Notification Filter Requirements

⚠️ **Critical:** Each notification rule MUST have non-overlapping filters to avoid AWS configuration errors.

**AWS will reject configurations with ambiguous/overlapping notification rules.**

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
      # NO prefix - overlaps with EVERYTHING!
    }
  }
}
# Error: Configuration is ambiguously defined
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
      events = ["s3:ObjectRemoved:*"]  # Different event type
      filter_prefix = "archived/"       # Different prefix
    }
  }
}
```

**Best practices:**

- Use unique prefix/suffix combinations for each rule
- Use different event types when possible (Created vs Removed)
- Always specify filter_prefix to avoid wildcards

See [complete example](./examples/complete/) for proper implementation.

## Inputs

For complete input documentation, see [variables.tf](./s3/23-variables.tf).

### Key Variables

| Name                | Description                                              | Type          | Default | Required |
| ------------------- | -------------------------------------------------------- | ------------- | ------- | -------- |
| `account_name`      | Account name for bucket naming (1-32 chars, `^[a-z0-9-]+$`) | `string`   | n/a     | yes      |
| `project_name`      | Project name for bucket naming (1-32 chars, `^[a-z0-9-]+$`) | `string`   | n/a     | yes      |
| `buckets`           | Map of bucket configurations                             | `map(object)` | n/a     | yes      |
| `create`            | Whether to create resources                              | `bool`        | `true`  | no       |
| `region_prefix`     | Region prefix override (auto-detected if null)           | `string`      | `null`  | no       |
| `use_region_prefix` | Include the region prefix in bucket names                | `bool`        | `true`  | no       |
| `tags_common`       | Common tags for all buckets                              | `map(string)` | `{}`    | no       |

### Bucket Configuration Object

Each bucket in the `buckets` map supports many options. Key options:

| Option                                            | Description                                                   | Type           | Default                 |
| ------------------------------------------------- | ------------------------------------------------------------- | -------------- | ----------------------- |
| `name`                                            | Explicit bucket name (overrides the generated name)           | `string`       | `null`                  |
| `force_destroy`                                   | Allow bucket deletion with objects                            | `bool`         | `false`                 |
| `enable_versioning`                               | Enable versioning                                             | `bool`         | `true`                  |
| `enable_encryption`                               | Enable encryption                                             | `bool`         | `true`                  |
| `encryption_type`                                 | SSE algorithm (AES256 or aws:kms)                             | `string`       | `"AES256"`              |
| `enable_public_access_block`                      | Block public access                                           | `bool`         | `true`                  |
| `object_ownership`                                | Object ownership                                              | `string`       | `"BucketOwnerEnforced"` |
| `create_bucket_policy`                            | Deny non-TLS requests (`aws:SecureTransport`)                 | `bool`         | `true`                  |
| `attach_require_latest_tls_policy`                | Deny requests with TLS < 1.2                                  | `bool`         | `false`                 |
| `attach_deny_unencrypted_object_uploads`          | Deny `PutObject` without SSE header                           | `bool`         | `false`                 |
| `attach_deny_ssec_encrypted_object_uploads`       | Deny `PutObject` with SSE-C                                   | `bool`         | `false`                 |
| `attach_elb_log_policy` / `attach_lb_log_policy`  | ALB/CLB access logs (ELB account + ELB log delivery service)  | `bool`         | `false`                 |
| `attach_lb_log_delivery_policy`                   | NLB access logs (`delivery.logs.amazonaws.com`)               | `bool`         | `false`                 |
| `attach_access_log_delivery_policy`               | S3 server access logs (`logging.s3.amazonaws.com`)            | `bool`         | `false`                 |
| `attach_cloudtrail_policy`                        | CloudTrail log delivery                                       | `bool`         | `false`                 |
| `attach_waf_log_policy`                           | WAF log delivery (`delivery.logs.amazonaws.com`)              | `bool`         | `false`                 |
| `custom_policy_statements`                        | Extra policy JSON (supports placeholders)                     | `string`       | `null`                  |
| `lifecycle_rules`                                 | Map of lifecycle rules                                        | `map(object)`  | `{}`                    |
| `lifecycle_transition_default_minimum_object_size`| `all_storage_classes_128K` or `varies_by_storage_class`       | `string`       | `null` (AWS default)    |
| `cors_rules`                                      | List of CORS rules                                            | `list(object)` | `[]`                    |
| `enable_website`                                  | Enable website hosting                                        | `bool`         | `false`                 |
| `enable_logging` / `logging_config`               | Server access logging to a target bucket                      | `bool`/`object`| `false` / `null`        |
| `enable_replication` / `replication_config`       | Replication                                                   | `bool`/`object`| `false` / `null`        |
| `enable_acceleration`                             | Enable transfer acceleration                                  | `bool`         | `false`                 |
| `object_lock_enabled`                             | Enable object lock (immutable at creation)                    | `bool`         | `false`                 |
| `object_lock_config`                              | Default retention (`mode` + `days` or `years`)                | `object`       | `null`                  |
| `inventory_configs` / `analytics_configs` / `metrics_configs` / `intelligent_tiering_configs` | Reporting and tiering        | `map(object)`  | `{}`                    |
| `notifications`                                   | SNS/SQS/Lambda/EventBridge notifications                      | `object`       | `null`                  |
| `tags`                                            | Bucket-specific tags                                          | `map(string)`  | `{}`                    |

See [complete example](./examples/complete/) for all available options.

## Outputs

27+ comprehensive outputs are provided. Key outputs:

| Name                     | Description                                 |
| ------------------------ | ------------------------------------------- |
| `bucket_names`           | Map of bucket keys to names (known at plan) |
| `bucket_ids`             | Map of bucket keys to IDs (names)           |
| `bucket_arns`            | Map of bucket keys to ARNs                  |
| `bucket_domain_names`    | Map of bucket keys to domain names          |
| `website_endpoints`      | Map of bucket keys to website endpoints     |
| `versioning_enabled`     | Map of bucket keys to versioning status     |
| `encryption_enabled`     | Map of bucket keys to encryption status     |
| `acceleration_endpoints` | Map of bucket keys to accelerated endpoints |
| `bucket_tags`            | Map of bucket keys to bucket tags           |
| `bucket_policies`        | Map of bucket keys to attached policy JSON  |
| `buckets_summary`        | Comprehensive summary of all configurations |

See [outputs.tf](./s3/24-outputs.tf) for all available outputs.

## Bucket Naming Convention

Buckets are automatically named using the pattern:

```
{region_prefix}-s3-{account_name}-{project_name}-{bucket_key}
```

**Example:** `ause1-s3-prod-myapp-data`

- With `use_region_prefix = false` the region prefix is omitted: `s3-prod-myapp-data`.
- A per-bucket `name` overrides the generated name (e.g. WAF requires `aws-waf-logs-*`).
- Names are checked at plan time against the S3 limit of 3-63 characters.

Every bucket gets the tags `merge(tags_common, { BucketKey, AccountName, ProjectName }, tags, { Name = <bucket name>, ManagedBy = "Terraform" })`.

### Region Prefix Auto-Detection

The module automatically detects the AWS region and applies the appropriate prefix:

| Region    | Prefix | Region         | Prefix |
| --------- | ------ | -------------- | ------ |
| us-east-1 | ause1  | eu-west-1      | euw1   |
| us-east-2 | ause2  | eu-west-2      | euw2   |
| us-west-1 | usw1   | eu-west-3      | euw3   |
| us-west-2 | usw2   | ap-southeast-1 | apse1  |

29 regions supported (unknown regions resolve to `unknown`). Override with `region_prefix` if needed.

> Note: this module keeps its historical short codes (`usw1`, `euw1`, …), which differ from the `ausw1`/`euwe1` codes used by other `jhonmezaa` modules. Changing them would rename (and therefore recreate) existing buckets, so they are kept for backward compatibility.

## Security Defaults

The module implements security best practices by default:

- ✅ **Encryption at Rest**: SSE-S3 (AES256) enabled
- ✅ **Versioning**: Enabled for data protection
- ✅ **Public Access Block**: All 4 settings enabled
- ✅ **TLS Enforcement**: Bucket policy denies non-HTTPS requests
- ✅ **Object Ownership**: BucketOwnerEnforced (disables ACLs)

To disable any default, explicitly set to `false`:

```hcl
buckets = {
  example = {
    enable_versioning = false # Only if absolutely necessary
  }
}
```

## Migration from v1.x

This is a **major version update** with breaking changes.

### Key Breaking Changes

1. **Variable Renames:**
   - `tags_backup_s3` → `tags`
   - `bucket_policy_default` → `create_bucket_policy`

2. **New Required Variable:**
   - `encryption_type` (default: `"AES256"`)

3. **Lifecycle Structure Changed:**
   - From single boolean flag to map of rules

4. **File Organization:**
   - Monolithic file split into 24 numbered files

See [CHANGELOG.md](./CHANGELOG.md) for complete list of changes.

## Module Architecture

```
s3/
├── 0-versions.tf               # Provider constraints
├── 1-bucket.tf                 # Core S3 bucket
├── 2-versioning.tf             # Versioning configuration
├── 3-encryption.tf             # Server-side encryption
├── 4-lifecycle.tf              # Lifecycle rules
├── 5-public-access-block.tf    # Public access blocking
├── 6-bucket-policy.tf          # Bucket policies
├── 7-website.tf                # Website hosting
├── 8-cors.tf                   # CORS configuration
├── 9-logging.tf                # Access logging
├── 10-acceleration.tf          # Transfer acceleration
├── 11-replication.tf           # Cross-region replication
├── 12-object-lock.tf           # Object locking
├── 13-intelligent-tiering.tf   # Intelligent-Tiering
├── 14-inventory.tf             # S3 Inventory
├── 15-analytics.tf             # Storage class analysis
├── 16-metrics.tf               # Request metrics
├── 17-notifications.tf         # Event notifications
├── 18-ownership-controls.tf    # Object ownership
├── 19-acl.tf                   # Bucket ACL
├── 20-request-payment.tf       # Request payment
├── 21-locals.tf                # Local transformations
├── 22-data.tf                  # Data sources
├── 23-variables.tf             # Input variables
└── 24-outputs.tf               # Output values
```

## Cost Optimization

The module includes features for cost optimization:

- **Lifecycle Transitions**: Automatic tiering to cheaper storage classes
- **Noncurrent Version Expiration**: Clean up old versions
- **Intelligent-Tiering**: Automatic optimization based on access patterns
- **Multipart Upload Cleanup**: Prevent storage of incomplete uploads
- **Request Metrics**: Monitor and optimize request patterns

## Testing

### Validate Configuration

```bash
cd s3/
terraform init
terraform validate
```

### Test Examples

```bash
cd examples/simple/
terraform init
terraform plan
```

All examples include comprehensive README files with testing instructions.

## License

This module is licensed under the MIT License. See [LICENSE](./LICENSE) for full details.

## Authors

Created and maintained by Jhon Meza.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Support

For issues and questions:

- Open an issue on GitHub
- Review the [examples/](./examples/) directory
- Check [CHANGELOG.md](./CHANGELOG.md) for upgrade guidance

## Resources

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/best-practices.html)
