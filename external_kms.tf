data "aws_iam_user" "breakglass" {
  user_name = "breakglass"
}

data "aws_iam_role" "ci" {
  name = "ci"
}

data "aws_iam_role" "administrator" {
  name = "administrator"
}

data "aws_iam_role" "aws_config" {
  name = "aws_config"
}

data "aws_iam_policy_document" "data_egress_ebs_cmk" {
  statement {
    sid    = "EnableIAMPermissionsBreakglass"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.breakglass.arn]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "EnableIAMPermissionsAccount"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [local.account[local.environment]]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "EnableIAMPermissionsCI"
    effect = "Allow"

    principals {
      identifiers = [data.aws_iam_role.ci.arn]
      type        = "AWS"
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "DenyCIEncryptDecrypt"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.ci.arn]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ImportKeyMaterial",
      "kms:ReEncryptFrom",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EnableIAMPermissionsAdministrator"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.administrator.arn]
    }

    actions = [
      "kms:Describe*",
      "kms:List*",
      "kms:Get*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EnableAWSConfigManagerScanForSecurityHub"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.aws_config.arn]
    }

    actions = [
      "kms:Describe*",
      "kms:Get*",
      "kms:List*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "EnableIAMPermissionsDataEgress"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.data_egress_server_task.arn, aws_iam_role.sft_agent_task.arn]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

  }

  statement {
    sid    = "AllowAwsCliveServiceGrant"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.data_egress_server_task.arn, aws_iam_role.sft_agent_task.arn]
    }

    actions = ["kms:CreateGrant"]

    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}



resource "aws_kms_external_key" "data_egress_ebs_cmk" {
  description             = "Encrypts data egress EBS volume. Key material is uploaded manually"
  deletion_window_in_days = 7
  enabled                 = true

  tags = merge(
    local.common_tags,
    {
      Name = local.data_egress_friendly_name
    }
  )
}

resource "aws_kms_alias" "data_egress_ebs_cmk" {
  name          = "alias/data_egress_ebs_cmk"
  target_key_id = aws_kms_external_key.data_egress_ebs_cmk.id
}

data "aws_iam_policy_document" "data_egress_ebs_cmk_encrypt" {
  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [aws_kms_external_key.data_egress_ebs_cmk.arn]
  }

  statement {
    effect = "Allow"

    actions = ["kms:CreateGrant"]

    resources = [aws_kms_external_key.data_egress_ebs_cmk.arn]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "data_egress_ebs_cmk_encrypt" {
  name        = "AwsDataEgressEbsCmkEncrypt"
  description = "Allow encryption and decryption using the data_egress EBS CMK"
  policy      = data.aws_iam_policy_document.data_egress_ebs_cmk_encrypt.json
}
