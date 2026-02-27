# Changelog

## [v2.0.3] - 2026-02-27

### Changed
- Standardize Terraform `required_version` to `~> 1.0` across module and examples


## [v2.0.2] - 2026-02-27

### Changed
- Update AWS provider constraint to `~> 6.0` across module and examples


All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2026-01-07

### Fixed

#### Replication Configuration (Schema V1)
- Fixed S3 replication configuration to use Schema V1 for maximum compatibility
- Removed `priority` attribute causing `InvalidRequest` errors in some AWS accounts
- Removed `delete_marker_replication` block not supported in Schema V1
- Simplified replication to single rule per bucket (Schema V1 limitation)
- Updated `s3/11-replication.tf` with detailed comments explaining Schema V1 vs V2 differences

#### Event Notifications
- Fixed notification filter overlapping causing `Configuration is ambiguously defined` errors
- Ensured all notification rules have non-overlapping prefix/suffix combinations
- Updated `s3/17-notifications.tf` to use inline for_each filtering (resolved dependency issues)

#### Lifecycle Rules
- Fixed lifecycle configuration filter block structure to eliminate Terraform warnings
- Changed from dynamic filter block to static block with conditional content
- Made expiration attributes mutually exclusive in `s3/4-lifecycle.tf`

#### Intelligent-Tiering
- Fixed ARCHIVE_ACCESS tier minimum days requirement (90 days minimum, was 30)
- Corrected validation in test configurations

### Added

#### Policy Placeholders System
- Implemented automatic placeholder replacement in custom bucket policies (`s3/21-locals.tf`)
- Added support for `{{BUCKET_ID}}`, `{{BUCKET_ARN}}`, `{{ACCOUNT_ID}}`, `{{REGION}}`
- Eliminates need for manual bucket name/ARN calculations in policies
- Documented in README with examples

#### Examples and Testing
- Added 6 comprehensive examples with full documentation:
  - `simple` - Basic bucket with security defaults
  - `with-versioning` - Advanced lifecycle rules
  - `static-website` - Website hosting with CORS
  - `with-replication` - Cross-region replication (Schema V1)
  - `log-delivery` - ELB/CloudTrail/WAF log buckets with placeholders
  - `complete` - All 22+ features enabled
- Created `examples/README.md` with feature comparison matrix
- Added automated validation script for all examples

#### Documentation
- Updated README with "Important Implementation Notes" section
- Added replication Schema V1 limitations documentation
- Added notification filter requirements documentation
- Created detailed troubleshooting guides in example READMEs

### Changed

#### Examples
- Updated `with-replication` example to use Schema V1 (single rule, no priority)
- Updated `log-delivery` example with placeholder demonstrations
- Updated `complete` example with non-overlapping notification filters
- All example READMEs rewritten with comprehensive implementation notes

#### Testing
- All 6 examples validated with `terraform init`, `terraform validate`, and `terraform plan`
- Comprehensive testing of all module features
- Validated with real AWS provider connectivity
- Zero errors in final validation

## [2.0.0] - 2026-01-05

### Added

#### Core Features (5)
- Region prefix auto-detection for 27 AWS regions
- Comprehensive locals.tf (21-locals.tf) with conditional maps and flattening patterns
- Support for SSE-KMS encryption with bucket keys
- MFA delete support for versioning

#### Lifecycle Management (6)
- Advanced lifecycle rules with multiple storage class transitions
- Object size filtering (greater than / less than)
- Tag-based filtering
- Prefix-based filtering
- Multiple lifecycle rules per bucket (map-based configuration)
- Abort incomplete multipart uploads configuration

#### Access & Security (4)
- Object ownership controls (BucketOwnerEnforced/BucketOwnerPreferred/ObjectWriter)
- Bucket ACL support (canned ACLs)
- Request payment configuration (Requester pays)
- Enhanced bucket policies (ELB, CloudTrail, WAF log delivery)

#### Website & CORS (2)
- Static website hosting configuration
- CORS rules with multiple origin/method support

#### Logging & Monitoring (4)
- Access logging configuration
- Request metrics (CloudWatch) with filtering
- Storage class analysis (Analytics)
- S3 Inventory reports (CSV/ORC/Parquet)

#### Advanced Features (7)
- Cross-region replication with RTC (Replication Time Control)
- Transfer acceleration
- Object Lock (COMPLIANCE/GOVERNANCE modes)
- Intelligent-Tiering configurations
- Event notifications (SNS, SQS, Lambda, EventBridge)
- Multiple intelligent-tiering configurations per bucket
- Flattened configuration support for advanced features

#### Outputs (20+)
- `bucket_arns` - Map of bucket ARNs
- `bucket_domain_names` - Bucket domain names
- `bucket_regional_domain_names` - Regional domain names
- `bucket_hosted_zone_ids` - Route 53 hosted zone IDs
- `website_endpoints` - Website endpoints
- `website_domains` - Website domains
- `encryption_algorithms` - Encryption algorithms used
- `kms_key_ids` - KMS key IDs for encrypted buckets
- `acceleration_status` - Transfer acceleration status
- `acceleration_endpoints` - Accelerated endpoints
- `replication_enabled` - Replication status
- `replication_role_arns` - Replication IAM role ARNs
- `object_lock_configuration` - Object lock settings
- `object_ownership` - Object ownership settings
- `request_payer` - Request payment configuration
- `notifications_enabled` - Notification status
- `eventbridge_enabled` - EventBridge integration status
- `*_configs_count` - Counts for various advanced features
- `buckets_summary` - Comprehensive configuration summary

#### Documentation & Examples
- 6 comprehensive examples with READMEs
- Complete module README with usage patterns
- MIGRATION.md guide for v1.x users
- CHANGELOG.md (this file)

### Changed

#### BREAKING CHANGES

**Variable Renames:**
- `tags_backup_s3` → `tags`
- `bucket_policy_default` → `create_bucket_policy`

**New Variables:**
- `encryption_type` (default: `"AES256"`) - Specify SSE-S3 or SSE-KMS
- `region_prefix` (optional) - Override auto-detected region prefix

**Lifecycle Structure:**
- **Before:** Single `enable_lifecycle` boolean
- **After:** Map of lifecycle rules with full configuration:
  ```hcl
  lifecycle_rules = {
    rule_name = {
      enabled = true
      transitions = [...]
      expiration_days = 90
      ...
    }
  }
  ```

**File Organization:**
- Monolithic `1-bucket.tf` split into 24 numbered files (0-24)
- Better separation of concerns
- Improved readability and maintainability

**Security Defaults:**
- Encryption now enabled by default (was optional)
- Versioning now enabled by default (was optional)
- Public access block now enabled by default (was optional)
- TLS enforcement policy now enabled by default (was optional)

**Output Structure:**
- Changed from single `bucket_ids` to 27+ comprehensive outputs
- All outputs now return maps keyed by bucket key

### Fixed
- Region prefix no longer hardcoded ("ause1")
- Bucket naming now dynamic based on region
- Lifecycle rules now support all AWS S3 capabilities
- Public access block properly handles all 4 independent settings

### Improved
- Module performance with conditional resource creation
- Documentation with 6 detailed examples
- Code organization with numbered file structure
- Variable validation with 9+ validation rules
- Security posture with defaults following AWS best practices

## [1.0.0] - 2024-12-13

### Initial Release
- Basic S3 bucket creation
- Versioning support
- Encryption support (SSE-S3 only)
- Basic lifecycle rules (noncurrent version expiration)
- Bucket policy support
- Public access block
- Single output (`bucket_ids`)

---

## Migration from v1.x to v2.0.0

See [MIGRATION.md](./MIGRATION.md) for detailed migration instructions.

## Version Support

- **v2.0.0+**: Terraform >= 1.0, AWS Provider >= 5.0
- **v1.0.x**: Terraform >= 1.0, AWS Provider >= 5.0
