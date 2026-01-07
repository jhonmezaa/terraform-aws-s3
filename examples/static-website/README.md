# S3 Static Website Hosting Example

This example demonstrates how to host a static website on S3 with CORS configuration and access logging.

## Features

- **Website Hosting**: Configured for static website serving
- **CORS Support**: Multiple CORS rules for different origins and methods
- **Public Access**: Controlled public read access via bucket policy
- **Access Logging**: All requests logged to separate bucket
- **Custom Error Pages**: Support for custom 404 error page
- **Versioning**: Enabled for easy rollback

## Architecture

```
┌─────────────────┐
│   CloudFront    │ (Optional - not in this example)
│    (CDN)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐        ┌─────────────────┐
│  Website Bucket │───────▶│  Logs Bucket    │
│  (Public Read)  │ logs   │  (Private)      │
└─────────────────┘        └─────────────────┘
```

## Website Configuration

### Index and Error Documents
- **Index**: `index.html` - served for directory requests
- **Error**: `error.html` - served for 404/403 errors

### CORS Rules

Two CORS rules configured:

1. **Read-only access** (GET, HEAD):
   - Allowed origins: Your domain + localhost
   - Allowed headers: All
   - Cache preflight: 3000 seconds

2. **Write access** (PUT, POST, DELETE):
   - Allowed origins: Your domain only
   - For authenticated uploads

## Usage

### 1. Deploy Infrastructure

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit domain_name in terraform.tfvars
terraform init
terraform apply
```

### 2. Create Website Content

Create a simple `index.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <title>My S3 Website</title>
</head>
<body>
    <h1>Hello from S3!</h1>
    <p>This website is hosted on Amazon S3.</p>
</body>
</html>
```

Create an `error.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <title>404 - Page Not Found</title>
</head>
<body>
    <h1>404 - Page Not Found</h1>
    <p>The page you're looking for doesn't exist.</p>
</body>
</html>
```

### 3. Upload Content

```bash
# Get bucket name
BUCKET=$(terraform output -raw website_bucket_id)

# Upload files
aws s3 cp index.html s3://$BUCKET/ --content-type text/html
aws s3 cp error.html s3://$BUCKET/ --content-type text/html

# Or sync entire directory
aws s3 sync ./website-content/ s3://$BUCKET/ --delete
```

### 4. Access Website

```bash
# Get website URL
terraform output website_url

# Or visit directly:
http://<bucket-name>.s3-website-us-east-1.amazonaws.com
```

## Public Access Configuration

This example requires specific public access settings:

```hcl
public_access_block_config = {
  block_public_acls       = true   # Block public ACLs
  block_public_policy     = false  # Allow public bucket policy
  ignore_public_acls      = true   # Ignore existing public ACLs
  restrict_public_buckets = false  # Allow public access via policy
}
```

## CORS Testing

Test CORS from JavaScript:

```javascript
// This will work from https://example.com
fetch('http://your-bucket.s3-website-us-east-1.amazonaws.com/data.json')
  .then(response => response.json())
  .then(data => console.log(data));
```

## Access Logs

Access logs are stored in the `website-logs` bucket:

```
s3://website-logs-bucket/access-logs/2024/01/05/log-file.txt
```

Log format includes:
- Request time
- Remote IP
- Request URI
- HTTP status
- Error code
- Bytes sent

## Integration with CloudFront (Optional)

For production websites, consider adding CloudFront:

1. **Benefits**:
   - HTTPS support
   - Custom domain names
   - Edge caching
   - DDoS protection

2. **Setup**:
   ```hcl
   resource "aws_cloudfront_distribution" "website" {
     origin {
       domain_name = module.s3_buckets.website_endpoints["website"]
       origin_id   = "S3-Website"
     }
     # ... additional CloudFront configuration
   }
   ```

## Cost Considerations

- **Storage**: ~$0.023 per GB/month
- **Requests**: ~$0.0004 per 1,000 GET requests
- **Data Transfer**: ~$0.09 per GB out (first 10 TB)
- **Logs**: Additional storage costs

## Security Best Practices

✅ **Implemented**:
- Encryption at rest (SSE-S3)
- Versioning enabled
- Access logging
- Controlled public access (read-only)
- TLS enforcement via bucket policy

🔐 **Additional Recommendations**:
- Use CloudFront for HTTPS
- Implement WAF rules
- Enable CloudTrail logging
- Regular security audits

## Cleanup

```bash
# Empty website bucket first
aws s3 rm s3://$(terraform output -raw website_bucket_id) --recursive

# Empty logs bucket
aws s3 rm s3://$(terraform output -raw logs_bucket_id) --recursive

# Destroy infrastructure
terraform destroy
```

## Troubleshooting

### 403 Forbidden
- Check bucket policy allows `s3:GetObject`
- Verify public access block settings
- Ensure object has correct permissions

### 404 Not Found
- Verify `index.html` exists in bucket root
- Check object key names (case-sensitive)
- Confirm website hosting is enabled

### CORS Errors
- Check allowed origins match your domain exactly
- Verify CORS headers in browser devtools
- Test from allowed origin

## Next Steps

- Add CloudFront distribution for HTTPS
- Configure Route 53 for custom domain
- Implement CI/CD for automatic deployments
- Add CloudWatch alarms for monitoring
