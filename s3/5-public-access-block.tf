# =============================================================================
# S3 Bucket Public Access Block
# =============================================================================
# Blocks public access to S3 buckets for security
# Provides four independent settings to prevent accidental public exposure

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = local.buckets_with_public_access_block

  bucket = aws_s3_bucket.this[each.key].id

  # Block public ACLs
  # Prevents granting public access via ACLs
  block_public_acls = coalesce(
    try(each.value.public_access_block_config.block_public_acls, null),
    true
  )

  # Block public bucket policies
  # Prevents adding bucket policies that grant public access
  block_public_policy = coalesce(
    try(each.value.public_access_block_config.block_public_policy, null),
    true
  )

  # Ignore public ACLs
  # Ignores all public ACLs on the bucket and objects
  ignore_public_acls = coalesce(
    try(each.value.public_access_block_config.ignore_public_acls, null),
    true
  )

  # Restrict public buckets
  # Restricts access to buckets with public policies to AWS services and authorized users only
  restrict_public_buckets = coalesce(
    try(each.value.public_access_block_config.restrict_public_buckets, null),
    true
  )
}
