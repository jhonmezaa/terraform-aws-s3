# =============================================================================
# Data Sources
# =============================================================================
# This file contains data sources used across the module

# -----------------------------------------------------------------------------
# AWS Region
# -----------------------------------------------------------------------------
# Used for automatic region prefix detection in locals.tf

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# AWS Caller Identity
# -----------------------------------------------------------------------------
# Used for account ID in bucket policies

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# AWS Partition
# -----------------------------------------------------------------------------
# Used to build partition-aware ARNs (aws, aws-cn, aws-us-gov)

data "aws_partition" "current" {}

# NOTE: data "aws_elb_service_account" was replaced by the static
# local.elb_service_accounts map (21-locals.tf). The data source fails in
# regions launched after August 2022, which only support the
# logdelivery.elasticloadbalancing.amazonaws.com service principal.
