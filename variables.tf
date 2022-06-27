variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Region where resources will be deployed."
}
variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Map of generic tags to assign to all possible resources."
}
variable "purpose" {
  type        = string
  default     = "backups"
  description = "Purpose of the resources being created."
}
variable "backup_radar_emails" {
  type        = list(string)
  default     = []
  description = "List of emails that will receive SNS notifications for AWS Backup jobs."
}
variable "use_default_vault" {
  type        = bool
  default     = false
  description = "Determines whether to use default backup vault or create one."
}