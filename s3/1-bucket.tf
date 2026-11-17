# =============================================================================
# S3 Bucket - Core Resource
# =============================================================================
# This file contains the main S3 bucket resource
# All other configurations (versioning, encryption, lifecycle, etc.) are in separate files

resource "aws_s3_bucket" "this" {
  for_each = local.buckets

  bucket        = local.bucket_names[each.key]
  force_destroy = each.value.force_destroy

  # Object lock must be enabled at bucket creation
  # Cannot be changed after bucket is created
  object_lock_enabled = each.value.object_lock_enabled

  tags = local.bucket_tags[each.key]

  lifecycle {
    prevent_destroy = false

    precondition {
      condition     = length(local.bucket_names[each.key]) >= 3 && length(local.bucket_names[each.key]) <= 63
      error_message = "El nombre del bucket '${local.bucket_names[each.key]}' debe tener entre 3 y 63 caracteres (límite de AWS S3). Acorta la clave del bucket, account_name/project_name o define un 'name' explícito."
    }
  }
}
