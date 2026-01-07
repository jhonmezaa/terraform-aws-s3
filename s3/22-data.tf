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
# ELB Service Account
# -----------------------------------------------------------------------------
# Used for ELB/ALB/NLB log delivery bucket policies
# Only created when at least one bucket has ELB log policy attached

data "aws_elb_service_account" "this" {
  count = length([
    for k, v in var.buckets :
    k if v.attach_elb_log_policy || v.attach_lb_log_policy
  ]) > 0 ? 1 : 0
}
