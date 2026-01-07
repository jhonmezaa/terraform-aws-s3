# =============================================================================
# S3 Bucket Website Configuration
# =============================================================================
# Configures static website hosting for S3 buckets
# Supports index/error documents, redirects, and routing rules

resource "aws_s3_bucket_website_configuration" "this" {
  for_each = local.buckets_with_website

  bucket = aws_s3_bucket.this[each.key].id

  # ---------------------------------------------------------------------------
  # Index Document
  # ---------------------------------------------------------------------------
  # Default document served when accessing the website root or subdirectories

  dynamic "index_document" {
    for_each = each.value.website_config.redirect_all_requests_to == null ? [1] : []

    content {
      suffix = each.value.website_config.index_document
    }
  }

  # ---------------------------------------------------------------------------
  # Error Document
  # ---------------------------------------------------------------------------
  # Document served when an error occurs (e.g., 404 Not Found)

  dynamic "error_document" {
    for_each = each.value.website_config.error_document != null && each.value.website_config.redirect_all_requests_to == null ? [1] : []

    content {
      key = each.value.website_config.error_document
    }
  }

  # ---------------------------------------------------------------------------
  # Redirect All Requests
  # ---------------------------------------------------------------------------
  # Redirects all requests to another host (e.g., for domain migration)

  dynamic "redirect_all_requests_to" {
    for_each = each.value.website_config.redirect_all_requests_to != null ? [1] : []

    content {
      host_name = each.value.website_config.redirect_all_requests_to.host_name
      protocol  = each.value.website_config.redirect_all_requests_to.protocol
    }
  }

  # ---------------------------------------------------------------------------
  # Routing Rules
  # ---------------------------------------------------------------------------
  # Advanced routing rules in JSON format for conditional redirects
  # Example: redirect based on HTTP error code or key prefix

  routing_rules = each.value.website_config.routing_rules
}
