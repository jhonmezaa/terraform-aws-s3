# =============================================================================
# S3 Bucket Policy
# =============================================================================
# Manages bucket policies with support for:
# - TLS/HTTPS enforcement (security default)
# - ELB/ALB/NLB access logging
# - CloudTrail log delivery
# - WAF log delivery
# - Custom policy statements

# -----------------------------------------------------------------------------
# Combined Bucket Policy
# -----------------------------------------------------------------------------
# Merges multiple policy types into a single policy document

data "aws_iam_policy_document" "combined" {
  for_each = {
    for k, v in var.buckets :
    k => v if v.create_bucket_policy || v.attach_elb_log_policy || v.attach_lb_log_policy || v.attach_cloudtrail_policy || v.attach_waf_log_policy || v.custom_policy_statements != null
  }

  # ---------------------------------------------------------------------------
  # TLS Enforcement Policy
  # ---------------------------------------------------------------------------
  # Denies all requests that don't use HTTPS/TLS
  # Security best practice to prevent man-in-the-middle attacks

  dynamic "statement" {
    for_each = each.value.create_bucket_policy ? [1] : []

    content {
      sid    = "DenyInsecureTransport"
      effect = "Deny"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions = [
        "s3:*",
      ]

      resources = [
        aws_s3_bucket.this[each.key].arn,
        "${aws_s3_bucket.this[each.key].arn}/*",
      ]

      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["false"]
      }
    }
  }

  # ---------------------------------------------------------------------------
  # ELB/ALB/NLB Log Delivery Policy
  # ---------------------------------------------------------------------------
  # Allows ELB service account to write access logs to bucket
  # Required for Application Load Balancer, Network Load Balancer, Classic Load Balancer logs

  dynamic "statement" {
    for_each = each.value.attach_elb_log_policy || each.value.attach_lb_log_policy ? [1] : []

    content {
      sid    = "AllowELBLogDelivery"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = [data.aws_elb_service_account.this[0].arn]
      }

      actions = [
        "s3:PutObject",
      ]

      resources = [
        "${aws_s3_bucket.this[each.key].arn}/*",
      ]
    }
  }

  # Additional statement for ELB to check bucket ACL
  dynamic "statement" {
    for_each = each.value.attach_elb_log_policy || each.value.attach_lb_log_policy ? [1] : []

    content {
      sid    = "AllowELBLogDeliveryAclCheck"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = [data.aws_elb_service_account.this[0].arn]
      }

      actions = [
        "s3:GetBucketAcl",
      ]

      resources = [
        aws_s3_bucket.this[each.key].arn,
      ]
    }
  }

  # ---------------------------------------------------------------------------
  # CloudTrail Log Delivery Policy
  # ---------------------------------------------------------------------------
  # Allows CloudTrail service to write audit logs to bucket
  # Required for AWS CloudTrail trail logging

  dynamic "statement" {
    for_each = each.value.attach_cloudtrail_policy ? [1] : []

    content {
      sid    = "AWSCloudTrailAclCheck"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }

      actions = [
        "s3:GetBucketAcl",
      ]

      resources = [
        aws_s3_bucket.this[each.key].arn,
      ]

      condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = ["arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/*"]
      }
    }
  }

  dynamic "statement" {
    for_each = each.value.attach_cloudtrail_policy ? [1] : []

    content {
      sid    = "AWSCloudTrailWrite"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }

      actions = [
        "s3:PutObject",
      ]

      resources = [
        "${aws_s3_bucket.this[each.key].arn}/*",
      ]

      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = ["arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/*"]
      }
    }
  }

  # ---------------------------------------------------------------------------
  # WAF Log Delivery Policy
  # ---------------------------------------------------------------------------
  # Allows AWS WAF to write web ACL logs to bucket
  # Required for AWS WAF logging

  dynamic "statement" {
    for_each = each.value.attach_waf_log_policy ? [1] : []

    content {
      sid    = "AWSLogDeliveryWrite"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["logging.s3.amazonaws.com"]
      }

      actions = [
        "s3:PutObject",
      ]

      resources = [
        "${aws_s3_bucket.this[each.key].arn}/*",
      ]

      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }

  dynamic "statement" {
    for_each = each.value.attach_waf_log_policy ? [1] : []

    content {
      sid    = "AWSLogDeliveryAclCheck"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["logging.s3.amazonaws.com"]
      }

      actions = [
        "s3:GetBucketAcl",
      ]

      resources = [
        aws_s3_bucket.this[each.key].arn,
      ]

      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Custom Policy Statements
  # ---------------------------------------------------------------------------
  # Allows users to provide additional custom policy statements in JSON format
  # Use case: Complex policies not covered by pre-defined options
  #
  # Supports placeholders for dynamic values:
  #   {{BUCKET_ID}}   - Replaced with bucket name
  #   {{BUCKET_ARN}}  - Replaced with bucket ARN
  #   {{ACCOUNT_ID}}  - Replaced with AWS account ID
  #   {{REGION}}      - Replaced with AWS region

  source_policy_documents = local.custom_policies_with_placeholders[each.key] != null ? [local.custom_policies_with_placeholders[each.key]] : []
}

# -----------------------------------------------------------------------------
# Bucket Policy Resource
# -----------------------------------------------------------------------------
# Applies the combined policy document to the S3 bucket

resource "aws_s3_bucket_policy" "this" {
  for_each = {
    for k, v in var.buckets :
    k => v if v.create_bucket_policy || v.attach_elb_log_policy || v.attach_lb_log_policy || v.attach_cloudtrail_policy || v.attach_waf_log_policy || v.custom_policy_statements != null
  }

  bucket = aws_s3_bucket.this[each.key].id
  policy = data.aws_iam_policy_document.combined[each.key].json
}
