# Simple S3 Bucket Example

This example demonstrates how to create a basic S3 bucket with security best practices enabled by default.

## Features Enabled

- **Encryption**: SSE-S3 (AES256)
- **Versioning**: Enabled
- **Public Access Block**: All 4 settings enabled
- **Bucket Policy**: TLS enforcement (HTTPS required)
- **Auto-naming**: Region prefix auto-detection

## Bucket Naming

The bucket will be automatically named following the pattern:
```
{region_prefix}-s3-{account_name}-{project_name}-{bucket_key}
```

Example: `ause1-s3-dev-example-data`

## Usage

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   ```hcl
   aws_region   = "us-east-1"
   account_name = "dev"
   project_name = "myapp"
   ```

3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. View outputs:
   ```bash
   terraform output
   ```

## Outputs

- `bucket_id` - The bucket name/ID
- `bucket_arn` - The bucket ARN
- `bucket_domain_name` - The bucket domain name
- `versioning_enabled` - Versioning status
- `encryption_enabled` - Encryption status
- `encryption_algorithm` - Encryption algorithm (AES256)
- `public_access_blocked` - Public access block status
- `bucket_summary` - Comprehensive configuration summary

## Security Features

All security features are enabled by default:

- ✅ Encryption at rest (SSE-S3)
- ✅ Versioning (protects against accidental deletion)
- ✅ Public access blocked (prevents accidental exposure)
- ✅ TLS enforcement (HTTPS required for all requests)

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

Note: `force_destroy = true` is set in this example to allow easy cleanup. In production, set this to `false` to prevent accidental deletion.
