region  = "us-east-2"
purpose = "backup-radar"
common_tags = { #environment tag automatically added, add programmatic tags in local.common_tags.
  repo       = "github/aws-backup-notifications"
  origin     = "resultant"
  created_by = "terraform"
}
backup_radar_emails = ["jwatson@resultant.com"]