terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Bucket d'état créé une seule fois à la main (voir README)
  backend "s3" {
    bucket       = "voicecraft-tfstate-636361171302"
    key          = "prod/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  name       = "${var.project}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id
  azs        = ["${var.region}a", "${var.region}b"]
}

# ============================================================
# Socle : chiffrement, réseau, logs
# ============================================================
module "kms" {
  source     = "./modules/kms"
  name       = local.name
  region     = var.region
  account_id = local.account_id
}

module "vpc" {
  source             = "./modules/vpc"
  name               = local.name
  region             = var.region
  vpc_cidr           = var.vpc_cidr
  azs                = local.azs
  kms_key_arn        = module.kms.key_arn
  log_retention_days = var.log_retention_days
  sandbox_port       = var.sandbox_port
}

module "logging" {
  source     = "./modules/logging"
  name       = local.name
  region     = var.region
  account_id = local.account_id
}

# ============================================================
# Exposition : DNS, certificat, ALB, WAF
# ============================================================
module "dns" {
  source           = "./modules/dns"
  hosted_zone_name = var.hosted_zone_name
  domain_name      = var.domain_name
  alb_dns_name     = module.alb.dns_name
  alb_zone_id      = module.alb.zone_id
}

module "acm" {
  source      = "./modules/acm"
  domain_name = var.domain_name
  zone_id     = module.dns.zone_id
}

module "alb" {
  source              = "./modules/alb"
  name                = local.name
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  alb_sg_id           = module.vpc.alb_sg_id
  certificate_arn     = module.acm.certificate_arn
  logs_bucket         = module.logging.bucket_id
  ssl_policy          = var.alb_ssl_policy
  backend_health_path = var.backend_health_path
}

module "waf" {
  source          = "./modules/waf"
  name            = local.name
  alb_arn         = module.alb.alb_arn
  logs_bucket_arn = module.logging.bucket_arn
  api_rate_limit  = var.waf_api_rate_limit
}

# ============================================================
# Application : images, secrets, base de données, ECS
# ============================================================
module "ecr" {
  source       = "./modules/ecr"
  name         = local.name
  repositories = var.ecr_repositories
  kms_key_arn  = module.kms.key_arn
}

module "secrets" {
  source      = "./modules/secrets"
  project     = var.project
  environment = var.environment
  kms_key_arn = module.kms.key_arn
}

module "docdb" {
  source            = "./modules/docdb"
  name              = local.name
  azs               = local.azs
  subnet_ids        = module.vpc.data_subnet_ids
  security_group_id = module.vpc.docdb_sg_id
  kms_key_arn       = module.kms.key_arn
  instance_class    = var.docdb_instance_class
  master_username   = var.docdb_master_username
}

module "ecs" {
  source             = "./modules/ecs"
  name               = local.name
  region             = var.region
  account_id         = local.account_id
  kms_key_arn        = module.kms.key_arn
  log_retention_days = var.log_retention_days

  repository_urls  = module.ecr.repository_urls
  image_tag        = var.image_tag
  cpu_architecture = var.cpu_architecture

  app_subnet_ids     = module.vpc.app_subnet_ids
  sandbox_subnet_ids = module.vpc.sandbox_subnet_ids
  frontend_sg_id     = module.vpc.frontend_sg_id
  backend_sg_id      = module.vpc.backend_sg_id
  sandbox_sg_id      = module.vpc.sandbox_sg_id

  frontend_target_group_arn = module.alb.frontend_target_group_arn
  backend_target_group_arn  = module.alb.backend_target_group_arn

  frontend_desired_count = var.frontend_desired_count
  backend_min_count      = var.backend_min_count
  backend_max_count      = var.backend_max_count
  backend_cpu_target     = var.backend_cpu_target
  sandbox_port           = var.sandbox_port
  sandbox_cpu            = var.sandbox_cpu
  sandbox_memory         = var.sandbox_memory

  docdb_endpoint        = module.docdb.endpoint
  docdb_reader_endpoint = module.docdb.reader_endpoint
  docdb_username        = module.docdb.master_username
  docdb_secret_arn      = module.docdb.master_secret_arn
  groq_api_key_arn      = module.secrets.groq_api_key_arn
  jwt_secret_arn        = module.secrets.jwt_secret_arn
}

# ============================================================
# CI/CD : rôle GitHub OIDC
# ============================================================
module "github_oidc" {
  source               = "./modules/github-oidc"
  name                 = local.name
  account_id           = local.account_id
  github_repositories  = var.github_repositories
  create_oidc_provider = var.create_github_oidc_provider
  ecr_repository_arns  = module.ecr.repository_arns
  kms_key_arn          = module.kms.key_arn
  tf_state_bucket      = var.tf_state_bucket
  extra_policy_arns    = var.github_terraform_policy_arns
}

# ============================================================
# Détection, conformité, sauvegarde, observabilité
# ============================================================
module "security" {
  source              = "./modules/security"
  name                = local.name
  region              = var.region
  account_id          = local.account_id
  logs_bucket         = module.logging.bucket_id
  trail_name          = module.logging.trail_name
  enable_guardduty    = var.enable_guardduty
  enable_security_hub = var.enable_security_hub
  enable_config       = var.enable_config
  enable_inspector    = var.enable_inspector
}

module "backup" {
  source        = "./modules/backup"
  name          = local.name
  kms_key_arn   = module.kms.key_arn
  resource_arns = [module.docdb.cluster_arn]
}

module "monitoring" {
  source             = "./modules/monitoring"
  name               = local.name
  region             = var.region
  account_id         = local.account_id
  kms_key_id         = module.kms.key_id
  alert_email        = var.alert_email
  monthly_budget_usd = var.monthly_budget_usd

  alb_arn_suffix                  = module.alb.arn_suffix
  backend_target_group_arn_suffix = module.alb.backend_target_group_arn_suffix
  app_cluster_name                = module.ecs.app_cluster_name
  backend_service_name            = module.ecs.backend_service_name
  frontend_service_name           = module.ecs.frontend_service_name
  docdb_cluster_identifier        = module.docdb.cluster_identifier
  waf_web_acl_name                = module.waf.web_acl_name
}