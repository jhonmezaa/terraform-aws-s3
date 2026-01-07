# =============================================================================
# S3 Bucket - Core Resource
# =============================================================================
# This file contains the main S3 bucket resource
# All other configurations (versioning, encryption, lifecycle, etc.) are in separate files

resource "aws_s3_bucket" "this" {
  for_each = var.create ? var.buckets : {}

  bucket        = local.bucket_names[each.key]
  force_destroy = each.value.force_destroy

  # Object lock must be enabled at bucket creation
  # Cannot be changed after bucket is created
  object_lock_enabled = each.value.object_lock_enabled

  tags = local.bucket_tags[each.key]

  lifecycle {
    prevent_destroy = false
  }
}
