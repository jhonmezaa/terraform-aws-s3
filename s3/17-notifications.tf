# =============================================================================
# S3 Bucket Notification Configuration
# =============================================================================
# Configures event notifications for S3 object operations
# Supports SNS topics, SQS queues, Lambda functions, and EventBridge

resource "aws_s3_bucket_notification" "this" {
  for_each = {
    for k, v in var.buckets :
    k => v if v.notifications != null && (
      length(try(v.notifications.sns_topics, {})) > 0 ||
      length(try(v.notifications.sqs_queues, {})) > 0 ||
      length(try(v.notifications.lambda_functions, {})) > 0 ||
      try(v.notifications.enable_eventbridge, false)
    )
  }

  bucket = aws_s3_bucket.this[each.key].id

  # ---------------------------------------------------------------------------
  # EventBridge Integration
  # ---------------------------------------------------------------------------
  # Send all S3 events to EventBridge (simplest option for event-driven architectures)

  eventbridge = try(each.value.notifications.enable_eventbridge, false)

  # ---------------------------------------------------------------------------
  # SNS Topic Notifications
  # ---------------------------------------------------------------------------
  # Send events to SNS topics for fan-out patterns

  dynamic "topic" {
    for_each = coalesce(each.value.notifications.sns_topics, {})

    content {
      id            = topic.key
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }

  # ---------------------------------------------------------------------------
  # SQS Queue Notifications
  # ---------------------------------------------------------------------------
  # Send events to SQS queues for async processing

  dynamic "queue" {
    for_each = coalesce(each.value.notifications.sqs_queues, {})

    content {
      id            = queue.key
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = queue.value.filter_prefix
      filter_suffix = queue.value.filter_suffix
    }
  }

  # ---------------------------------------------------------------------------
  # Lambda Function Notifications
  # ---------------------------------------------------------------------------
  # Trigger Lambda functions directly from S3 events

  dynamic "lambda_function" {
    for_each = coalesce(each.value.notifications.lambda_functions, {})

    content {
      id                  = lambda_function.key
      lambda_function_arn = lambda_function.value.function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }
}
