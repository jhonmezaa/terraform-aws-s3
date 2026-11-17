# =============================================================================
# S3 Bucket Policy
# =============================================================================
# Manages bucket policies with support for:
# - TLS/HTTPS enforcement (security default)
# - ELB/ALB/NLB access logging
# - S3 server access log delivery
# - CloudTrail log delivery
# - WAF log delivery
# - TLS 1.2+ and upload encryption guardrails
# - Custom policy statements

# -----------------------------------------------------------------------------
# Combined Bucket Policy
# -----------------------------------------------------------------------------
# Merges multiple policy types into a single policy document

data "aws_iam_policy_document" "combined" {
  for_each = local.buckets_with_any_policy

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
  # ELB/ALB Log Delivery Policy
  # ---------------------------------------------------------------------------
  # Allows Elastic Load Balancing to write access logs to the bucket.
  # - Regions created before August 2022: regional ELB service account
  # - Regions created after August 2022: logdelivery.elasticloadbalancing service principal

  dynamic "statement" {
    for_each = (each.value.attach_elb_log_policy || each.value.attach_lb_log_policy) && local.elb_service_account_arn != null ? [1] : []

    content {
      sid    = "AllowELBLogDelivery"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = [local.elb_service_account_arn]
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
    for_each = (each.value.attach_elb_log_policy || each.value.attach_lb_log_policy) && local.elb_service_account_arn != null ? [1] : []

    content {
      sid    = "AllowELBLogDeliveryAclCheck"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = [local.elb_service_account_arn]
      }

      actions = [
        "s3:GetBucketAcl",
      ]

      resources = [
        aws_s3_bucket.this[each.key].arn,
      ]
    }
  }

  dynamic "statement" {
    for_each = each.value.attach_elb_log_policy || each.value.attach_lb_log_policy ? [1] : []

    content {
      sid    = "AllowELBLogDeliveryServicePrincipal"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      }

      actions = [
        "s3:PutObject",
      ]

      resources = [
        "${aws_s3_bucket.this[each.key].arn}/*",
      ]
    }
  }

  # ---------------------------------------------------------------------------
  # NLB (and ALB via log delivery service) Log Delivery Policy
  # ---------------------------------------------------------------------------
  # Network Load Balancer access logs are delivered by delivery.logs.amazonaws.com

  dynamic "statement" {
    for_each = each.value.attach_lb_log_delivery_policy ? [1] : []

    content {
      sid    = "AlbNlbLogDeliveryWrite"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["delivery.logs.amazonaws.com"]
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
    }
  }

  dynamic "statement" {
    for_each = each.value.attach_lb_log_delivery_policy ? [1] : []

    content {
      sid    = "AlbNlbLogDeliveryAclCheck"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["delivery.logs.amazonaws.com"]
      }

      actions = [
        "s3:GetBucketAcl",
        "s3:ListBucket",
      ]

      resources = [
        aws_s3_bucket.this[each.key].arn,
      ]
    }
  }

  # ---------------------------------------------------------------------------
  # S3 Server Access Log Delivery Policy
  # ---------------------------------------------------------------------------
  # Allows the S3 logging service to write server access logs into this bucket
  # (required when the target bucket uses BucketOwnerEnforced, where the
  # log-delivery-write ACL cannot be used)

  dynamic "statement" {
    for_each = each.value.attach_access_log_delivery_policy ? [1] : []

    content {
      sid    = "AWSAccessLogDeliveryWrite"
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
        values   = [local.account_id]
      }
    }
  }

  dynamic "statement" {
    for_each = each.value.attach_access_log_delivery_policy ? [1] : []

    content {
      sid    = "AWSAccessLogDeliveryAclCheck"
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
        values   = [local.account_id]
      }
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
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = ["arn:${local.partition}:cloudtrail:${local.region}:${local.account_id}:trail/*"]
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
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = ["arn:${local.partition}:cloudtrail:${local.region}:${local.account_id}:trail/*"]
      }
    }
  }

  # ---------------------------------------------------------------------------
  # WAF Log Delivery Policy
  # ---------------------------------------------------------------------------
  # Allows AWS WAF (via the CloudWatch Logs delivery service) to write web ACL
  # logs to the bucket. NOTE: AWS WAF requires the bucket name to start with
  # "aws-waf-logs-" (use the per-bucket `name` override).

  dynamic "statement" {
    for_each = each.value.attach_waf_log_policy ? [1] : []

    content {
      sid    = "AWSLogDeliveryWrite"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["delivery.logs.amazonaws.com"]
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
        variable = "aws:SourceAccount"
        values   = [local.account_id]
      }

      condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = ["arn:${local.partition}:logs:*:${local.account_id}:*"]
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
        identifiers = ["delivery.logs.amazonaws.com"]
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
        values   = [local.account_id]
      }

      condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = ["arn:${local.partition}:logs:*:${local.account_id}:*"]
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Require TLS 1.2+
  # ---------------------------------------------------------------------------

  dynamic "statement" {
    for_each = each.value.attach_require_latest_tls_policy ? [1] : []

    content {
      sid    = "DenyOutdatedTLS"
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
        test     = "NumericLessThan"
        variable = "s3:TlsVersion"
        values   = ["1.2"]
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Deny object uploads without a server-side encryption header
  # ---------------------------------------------------------------------------

  dynamic "statement" {
    for_each = each.value.attach_deny_unencrypted_object_uploads ? [1] : []

    content {
      sid    = "DenyUnencryptedObjectUploads"
      effect = "Deny"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions = [
        "s3:PutObject",
      ]

      resources = [
        "${aws_s3_bucket.this[each.key].arn}/*",
      ]

      condition {
        test     = "Null"
        variable = "s3:x-amz-server-side-encryption"
        values   = ["true"]
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Deny SSE-C encrypted object uploads
  # ---------------------------------------------------------------------------

  dynamic "statement" {
    for_each = each.value.attach_deny_ssec_encrypted_object_uploads ? [1] : []

    content {
      sid    = "DenySSECEncryptedObjectUploads"
      effect = "Deny"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions = [
        "s3:PutObject",
      ]

      resources = [
        "${aws_s3_bucket.this[each.key].arn}/*",
      ]

      condition {
        test     = "Null"
        variable = "s3:x-amz-server-side-encryption-customer-algorithm"
        values   = ["false"]
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
  for_each = local.buckets_with_any_policy

  bucket = aws_s3_bucket.this[each.key].id
  policy = data.aws_iam_policy_document.combined[each.key].json

  # Chain bucket -> public access block -> policy to avoid
  # "A conflicting conditional operation is currently in progress"
  depends_on = [aws_s3_bucket_public_access_block.this]
}
