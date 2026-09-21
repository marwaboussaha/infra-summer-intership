variable "name" { type = string }
variable "region" { type = string }
variable "account_id" { type = string }
variable "kms_key_id" { type = string }
variable "alert_email" { type = string }
variable "monthly_budget_usd" { type = number }

variable "alb_arn_suffix" { type = string }
variable "backend_target_group_arn_suffix" { type = string }
variable "app_cluster_name" { type = string }
variable "backend_service_name" { type = string }
variable "frontend_service_name" { type = string }
variable "docdb_cluster_identifier" { type = string }
variable "waf_web_acl_name" { type = string }
