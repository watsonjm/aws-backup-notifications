resource "aws_backup_vault" "this" {
  name        = "${local.name_tag}-backup-vault"
  kms_key_arn = aws_kms_key.this.arn
  tags        = { Name = "${local.name_tag}-backup-vault" }
}

resource "aws_kms_key" "this" {
  description             = "BackupRadar Backup Vault Key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.backup.json
  tags                    = { Name = "backupradar-backup-vault-key" }
}

data "aws_iam_policy_document" "backup" {
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]
    effect    = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        data.aws_caller_identity.current.arn,
      ]
    }
  }
}

resource "aws_backup_plan" "plan1" {
  name = "Daily-35day-Retention"

  rule {
    rule_name                = "DailyBackups"
    start_window             = 480
    completion_window        = 10080
    enable_continuous_backup = false
    recovery_point_tags      = local.common_tags
    schedule                 = "cron(0 5 ? * * *)"
    target_vault_name        = aws_backup_vault.this.name

    lifecycle {
      cold_storage_after = 0
      delete_after       = 35
    }
  }

  tags = { Name = "${local.name_tag}-backup-plan" }
}

resource "aws_backup_plan" "plan2" {
  name = "Daily-Monthly-1yr-Retention"

  rule {
    rule_name                = "DailyBackups"
    start_window             = 480
    completion_window        = 10080
    enable_continuous_backup = false
    recovery_point_tags      = local.common_tags
    schedule                 = "cron(0 5 ? * * *)"
    target_vault_name        = aws_backup_vault.this.name

    lifecycle {
      cold_storage_after = 0
      delete_after       = 35
    }
  }
  rule {
    rule_name                = "MonthlyBackups"
    start_window             = 480
    completion_window        = 10080
    enable_continuous_backup = false
    recovery_point_tags      = local.common_tags
    schedule                 = "cron(0 5 1 * ? *)"
    target_vault_name        = aws_backup_vault.this.name

    lifecycle {
      cold_storage_after = 30
      delete_after       = 365
    }
  }

  tags = { Name = "${local.name_tag}-backup-plan" }
}

resource "aws_backup_plan" "plan3" {
  name = "Daily-Weekly-Monthly-5yr-Retention"

  rule {
    rule_name                = "DailyBackups"
    start_window             = 480
    completion_window        = 10080
    enable_continuous_backup = false
    recovery_point_tags      = local.common_tags
    schedule                 = "cron(0 5 ? * * *)"
    target_vault_name        = aws_backup_vault.this.name

    lifecycle {
      cold_storage_after = 0
      delete_after       = 35
    }
  }
  rule {
    rule_name                = "WeeklyBackups"
    start_window             = 480
    completion_window        = 10080
    enable_continuous_backup = false
    recovery_point_tags      = local.common_tags
    schedule                 = "cron(0 5 ? * 7 *)"
    target_vault_name        = aws_backup_vault.this.name

    lifecycle {
      cold_storage_after = 0
      delete_after       = 90
    }
  }
  rule {
    rule_name                = "MonthlyBackups"
    start_window             = 480
    completion_window        = 10080
    enable_continuous_backup = false
    recovery_point_tags      = local.common_tags
    schedule                 = "cron(0 5 1 * ? *)"
    target_vault_name        = aws_backup_vault.this.name

    lifecycle {
      cold_storage_after = 90
      delete_after       = 1825
    }
  }

  tags = { Name = "${local.name_tag}-backup-plan" }
}

resource "aws_backup_selection" "plans" {
  for_each = { for each in [
    aws_backup_plan.plan1,
    aws_backup_plan.plan2,
    aws_backup_plan.plan3
  ] : each.name => each.id }
  name         = "${local.name_tag}-backup-selection"
  plan_id      = each.value
  iam_role_arn = data.aws_iam_role.backup.arn
  resources = [
    "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
    "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*"
  ]
  condition {
    string_equals {
      key   = "aws:ResourceTag/backup_plan"
      value = each.key
    }
  }
}

data "aws_iam_role" "backup" {
  name = "AWSBackupDefaultServiceRole"
}

module "sns_emails" {
  source          = "github.com/watsonjm/tf-sns-email-topic-subscription?ref=v1.0"
  email_list_name = "backup-alerts"
  email_list      = var.backup_radar_emails
  name_tag        = local.name_tag
}

resource "aws_sns_topic_policy" "backup" {
  arn    = module.sns_emails.sns_topic.arn
  policy = data.aws_iam_policy_document.sns.json
}

data "aws_iam_policy_document" "sns" {
  statement {
    actions = ["SNS:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    resources = [
      module.sns_emails.sns_topic.arn,
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# This notification is straight from backup vault
resource "aws_backup_vault_notifications" "backups" {
  backup_vault_name   = aws_backup_vault.this.name
  sns_topic_arn       = module.sns_emails.sns_topic.arn
  backup_vault_events = ["BACKUP_JOB_COMPLETED", "BACKUP_JOB_SUCCESSFUL", "BACKUP_JOB_FAILED"]
}

#this notification is the one Backup Radar recommends, but is not thorough
resource "aws_cloudwatch_event_rule" "ebs_backups" {
  name        = "backup-radar"
  description = "Sends backup info to backup radar"

  event_pattern = jsonencode(
    {
      detail = {
        event = [
          "createSnapshot",
        ]
      }
      detail-type = [
        "EBS Snapshot Notification",
      ]
      source = [
        "aws.ec2",
      ]
    }
  )
}

resource "aws_cloudwatch_event_target" "ebs_sns" {
  arn       = module.sns_emails.sns_topic.arn
  rule      = aws_cloudwatch_event_rule.ebs_backups.name
  target_id = "backup-radar-ebs-sns"
}

# This notification is for the entire backup job, probably more useful
resource "aws_cloudwatch_event_rule" "ec2_backups" {
  name        = "backup-radar"
  description = "Sends backup info to backup radar"

  event_pattern = jsonencode(
    {
      detail-type = [
        "Backup Job State Change",
      ]
      source = [
        "aws.backup",
      ]
    }
  )
}

resource "aws_cloudwatch_event_target" "ec2_sns" {
  arn       = module.sns_emails.sns_topic.arn
  rule      = aws_cloudwatch_event_rule.ec2_backups.name
  target_id = "backup-radar-ec2-sns"
}