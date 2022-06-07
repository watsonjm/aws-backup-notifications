locals {
  common_tags = merge({
    purpose = var.purpose
    },
  var.common_tags)
  name_tag = var.purpose
}