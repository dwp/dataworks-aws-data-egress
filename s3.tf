resource "random_id" "rtg_temp_bucket" {
  byte_length = 16
}

resource "aws_kms_key" "rtg_temp_bucket_cmk" {
  description             = "RTG temp Bucket Master Key"
  deletion_window_in_days = 7
  is_enabled              = true
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      "Name" = "rtg_temp_bucket_cmk"
    },
    {
      "requires-custom-key-policy" = "false"
    },
  )
}

resource "aws_kms_alias" "rtg_temp_bucket_alias" {
  name          = "alias/rtg_temp_bucket"
  target_key_id = aws_kms_key.rtg_temp_bucket_cmk.key_id
}

resource "aws_s3_bucket" "rtg_temp" {
  bucket = random_id.rtg_temp_bucket.hex
  acl    = "private"
  tags = merge(
    local.common_tags,
    {
      Name = "rtg_temp_bucket"
    },
  )

  versioning {
    enabled = false
  }

  lifecycle_rule {
    id      = "DeleteBucketData"
    prefix  = ""
    enabled = true

    expiration {
      days = 1
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.rtg_temp_bucket_cmk.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

data "aws_iam_policy_document" "rtg_temp_bucket" {
  statement {
    sid     = "BlockHTTP"
    effect  = "Deny"
    actions = ["*"]

    resources = [
      aws_s3_bucket.rtg_temp.arn,
      "${aws_s3_bucket.rtg_temp.arn}/*",
    ]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

resource "aws_s3_bucket_policy" "rtg_temp" {
  bucket = aws_s3_bucket.rtg_temp.id
  policy = data.aws_iam_policy_document.rtg_temp_bucket.json
}

resource "aws_s3_bucket_public_access_block" "rtg_temp" {
  bucket = aws_s3_bucket.rtg_temp.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true

  depends_on = [
    aws_s3_bucket_policy.rtg_temp
  ]
}

output "rtg_temp_bucket" {
  value = {
    id  = aws_s3_bucket.rtg_temp.id
    arn = aws_s3_bucket.rtg_temp.arn
  }
}

output "rtg_temp_bucket_cmk" {
  value = {
    arn = aws_kms_key.rtg_temp_bucket_cmk.arn
  }
}
