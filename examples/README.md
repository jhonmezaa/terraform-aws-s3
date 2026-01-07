# S3 Module Examples

This directory contains 6 complete examples demonstrating various use cases and features of the terraform-aws-s3 module.

## Available Examples

### 1. [simple](./simple/)
Basic S3 bucket with security defaults:
- ✅ Encryption (SSE-S3)
- ✅ Versioning
- ✅ Public access block
- ✅ TLS enforcement

**Use Case:** Quick start, basic storage needs, development environments

---

### 2. [with-versioning](./with-versioning/)
Advanced versioning and lifecycle management:
- ✅ Multi-tier storage transitions (5 storage classes)
- ✅ Noncurrent version management
- ✅ Prefix-based lifecycle rules
- ✅ Cost optimization strategies

**Use Case:** Data retention, compliance, cost optimization, backups

---

### 3. [static-website](./static-website/)
Static website hosting with CORS:
- ✅ Website hosting configuration
- ✅ Multiple CORS rules
- ✅ Public read access
- ✅ Access logging
- ✅ Custom error pages

**Use Case:** Static websites, SPAs, documentation sites

---

### 4. [with-replication](./with-replication/)
Cross-region replication for disaster recovery:
- ✅ Cross-Region Replication (CRR)
- ✅ IAM role setup
- ✅ Schema V1 implementation
- ⚠️ Basic replication (no priority, metrics, or delete marker replication)

**Use Case:** Disaster recovery, compliance, geo-redundancy

**Note:** Uses Replication Schema V1 for maximum compatibility across all AWS accounts.

---

### 5. [log-delivery](./log-delivery/)
Log storage buckets with appropriate policies:
- ✅ ELB/ALB/NLB access logs
- ✅ CloudTrail audit logs
- ✅ WAF logs
- ✅ Application logs with custom policies
- ✅ **Policy placeholders** demonstration

**Use Case:** Centralized logging, compliance, audit trails

**Features:** Demonstrates the placeholder system ({{BUCKET_ID}}, {{BUCKET_ARN}}, {{ACCOUNT_ID}}, {{REGION}})

---

### 6. [complete](./complete/)
Reference implementation with ALL features:
- ✅ Advanced lifecycle rules (3 rules)
- ✅ Intelligent-Tiering
- ✅ S3 Inventory
- ✅ Storage class analysis
- ✅ Request metrics
- ✅ Event notifications (Lambda + SNS + EventBridge)
- ✅ Transfer acceleration
- ✅ Object Lock
- ✅ Custom policies with placeholders
- ✅ Full observability

**Use Case:** Production workloads, feature showcase, reference implementation

---

## Quick Start

Each example can be deployed independently:

```bash
# Navigate to desired example
cd simple/

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Deploy
terraform init
terraform plan
terraform apply

# Cleanup
terraform destroy
```

## Validation Script

A validation script is provided to test all examples:

```bash
# From examples directory
./validate-all.sh
```

This script will:
1. Run `terraform init` on each example
2. Run `terraform validate` to check syntax
3. Run `terraform fmt -check` to verify formatting
4. Provide a comprehensive summary

**Output:**
```
╔════════════════════════════════════════════════════════════════════╗
║            S3 Module Examples Validation Script                   ║
╚════════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Validating: simple
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ terraform init successful
✓ terraform validate successful
✓ terraform fmt check passed
✓ simple validation PASSED

[... output for all 6 examples ...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                          VALIDATION SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total examples:   6
Passed:           6
Failed:           0

╔════════════════════════════════════════════════════════════════════╗
║              ALL EXAMPLES VALIDATED SUCCESSFULLY!                  ║
╚════════════════════════════════════════════════════════════════════╝
```

## Features Comparison Matrix

| Feature | simple | versioning | website | replication | log-delivery | complete |
|---------|--------|------------|---------|-------------|--------------|----------|
| **Core** |
| Encryption | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Versioning | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Public Access Block | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| Bucket Policy | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Advanced** |
| Lifecycle Rules | ❌ | ✅✅✅ | ❌ | ❌ | ✅✅✅ | ✅✅✅ |
| Website Hosting | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| CORS | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Replication | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Logging | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| Acceleration | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Object Lock | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Intelligent-Tiering | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Inventory | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Analytics | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Metrics | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Notifications | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Policies** |
| TLS Enforcement | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| ELB Log Delivery | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| CloudTrail Policy | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| WAF Policy | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Custom Policy | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Placeholders | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |

**Legend:**
- ✅ = Feature enabled
- ✅✅✅ = Multiple instances/configurations
- ⚠️ = Partial (website needs specific config)
- ❌ = Not used in this example

## Important Implementation Notes

### 1. Replication Schema V1 vs V2

The `with-replication` example uses **Schema V1** (basic) because Schema V2 (advanced) is not universally available across all AWS accounts:

**Schema V1 (Used in examples):**
- ✅ Works in all AWS accounts/regions
- ✅ Single replication rule
- ✅ Basic destination configuration
- ❌ No priority attribute
- ❌ No delete marker replication
- ❌ No replication metrics
- ❌ No Replication Time Control (RTC)

**Schema V2 (Not used):**
- ⚠️ Not available in all AWS accounts (causes API errors)
- ✅ Multiple replication rules
- ✅ Priority attribute
- ✅ Delete marker replication
- ✅ Replication metrics
- ✅ Replication Time Control (RTC)

### 2. Policy Placeholders

The module supports **automatic placeholder replacement** in custom bucket policies:

```hcl
custom_policy_statements = jsonencode({
  Statement = [{
    Principal = { AWS = "arn:aws:iam::{{ACCOUNT_ID}}:root" }
    Resource = "{{BUCKET_ARN}}/*"
  }]
})
```

Available placeholders:
- `{{BUCKET_ID}}` → Actual bucket name
- `{{BUCKET_ARN}}` → Bucket ARN
- `{{ACCOUNT_ID}}` → AWS Account ID
- `{{REGION}}` → AWS Region

See `log-delivery` and `complete` examples for usage.

### 3. Notification Filter Requirements

**Critical:** Event notification rules MUST have non-overlapping filters to avoid AWS errors.

❌ **Bad - Will fail:**
```hcl
notifications = {
  lambda_functions = {
    handler1 = { events = ["s3:ObjectCreated:*"] }
  }
  sns_topics = {
    alerts = { events = ["s3:ObjectCreated:*"] }  # Overlaps!
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

See `complete` example for proper implementation.

## Cost Estimates

Approximate monthly costs for each example (1 TB storage, 1M requests):

| Example | Storage | Requests | Features | Total Est. |
|---------|---------|----------|----------|------------|
| simple | $23.00 | $0.40 | - | **~$23.40** |
| with-versioning | $28.00 | $0.40 | Transitions | **~$28.50** |
| static-website | $23.00 | $0.40 | Logging | **~$24.00** |
| with-replication | $46.00 | $0.80 | Transfer | **~$48.80** |
| log-delivery | $23.00 | $0.40 | - | **~$23.40** |
| complete | $23.00 | $0.40 | All features | **~$31.00** |

**Notes:**
- Costs exclude data transfer out
- Replication doubles storage costs (primary + replica)
- Complete example includes Inventory ($2.50), Analytics ($0.10), Intelligent-Tiering ($0.25)

## Production Checklist

Before deploying to production:

- [ ] Set `force_destroy = false` to prevent accidental deletion
- [ ] Review and adjust retention periods for compliance
- [ ] Configure actual notification targets (replace placeholder ARNs)
- [ ] Set up destination buckets for inventory/analytics/logging
- [ ] Enable MFA delete for critical buckets
- [ ] Configure backup automation (AWS Backup)
- [ ] Review costs and enable Cost Allocation Tags
- [ ] Set up CloudWatch alarms for monitoring
- [ ] Document recovery procedures
- [ ] Test restore procedures

## Testing

Each example includes testing instructions in its README:

1. **simple**: Basic upload/download testing
2. **with-versioning**: Lifecycle rule verification
3. **static-website**: Website access and CORS testing
4. **with-replication**: Replication status verification
5. **log-delivery**: Log delivery confirmation
6. **complete**: Comprehensive feature testing

## Troubleshooting

### Common Issues

**Validation errors:**
```bash
# Run validation script for detailed output
./validate-all.sh
```

**Format issues:**
```bash
# Auto-format all examples
cd simple && terraform fmt -recursive
cd ../with-versioning && terraform fmt -recursive
# ... repeat for each example
```

**Provider version conflicts:**
```bash
# Upgrade providers in all examples
cd simple && terraform init -upgrade
# ... repeat for each example
```

### Getting Help

- Check individual example READMEs for specific issues
- Review [module documentation](../s3/)
- Check [TEST-RESULTS.md](../deploy/TEST-RESULTS.md) for validation history
- Open an issue with:
  - Example name
  - Terraform version
  - AWS provider version
  - Full error message

## Contributing

When adding new examples:

1. Follow the numbered file convention (main.tf, variables.tf, outputs.tf, versions.tf)
2. Include a comprehensive README.md
3. Add terraform.tfvars.example
4. Update this README with the new example
5. Run `./validate-all.sh` to ensure all examples still work
6. Update the features comparison matrix

## Related Documentation

- [Main module README](../s3/README.md)
- [Testing results](../deploy/TEST-RESULTS.md)
- [Module variables](../s3/23-variables.tf)
- [Module outputs](../s3/24-outputs.tf)
