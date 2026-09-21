# voicecraft-infra

Infrastructure AWS de VoiceCraft (eu-west-3, Paris) en Terraform modulaire.

## Arborescence

```
.
├── .github/workflows/infra.yml   Gitleaks → Checkov/tfsec → plan → apply (manuel)
├── examples/app-repo-workflow.yml Pipeline du dépôt applicatif (Sonar, Snyk, build, Trivy, ECR)
├── modules/
│   ├── kms/          CMK avec rotation
│   ├── vpc/          VPC, 10 subnets, IGW, NAT x2, route tables, flow logs, endpoints, security groups
│   ├── logging/      Bucket S3 de logs (ALB, WAF, CloudTrail, Config)
│   ├── dns/          Zone Route 53 + alias vers l'ALB
│   ├── acm/          Certificat TLS + validation DNS
│   ├── alb/          ALB, target groups, routage / et /api/*
│   ├── waf/          WAF : rate limit /api + règles managées
│   ├── ecr/          4 dépôts immuables, scan, KMS
│   ├── secrets/      SSM : clé Groq, secret JWT
│   ├── docdb/        DocumentDB Multi-AZ chiffré, TLS
│   ├── ecs/          Clusters app + sandbox, services, auto scaling, rôles IAM des tâches
│   ├── github-oidc/  Rôle github_deploy (OIDC, branche main)
│   ├── security/     GuardDuty, Security Hub, Inspector, Access Analyzer, CloudTrail, Config
│   ├── backup/       AWS Backup 35 jours
│   └── monitoring/   SNS, alarmes, EventBridge, budget, dashboard
├── main.tf           provider, backend, appels des modules
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── .checkov.yaml
└── .gitignore
```

## Premier déploiement (en local, compte admin)

```bash
# 1. Bucket d'état (une seule fois) puis reporter le nom dans main.tf
aws s3api create-bucket --bucket MON-BUCKET-tfstate --region eu-west-3 \
  --create-bucket-configuration LocationConstraint=eu-west-3
aws s3api put-bucket-versioning --bucket MON-BUCKET-tfstate \
  --versioning-configuration Status=Enabled

# 2. Variables
cp terraform.tfvars.example terraform.tfvars   # puis remplir

# 3. Dépôts ECR + rôle CI d'abord
terraform init
terraform apply -target=module.ecr -target=module.github_oidc

# 4. Pousser une première version des 4 images (tag = image_tag), puis :
terraform apply

# 5. Clé Groq (jamais dans Terraform)
aws ssm put-parameter --name /voicecraft/prod/groq_api_key --type SecureString \
  --key-id alias/voicecraft-prod --value "gsk_..." --overwrite
```

## Configuration GitHub du dépôt infra

Variables (Settings → Secrets and variables → Actions → Variables) :

| Variable | Exemple |
|---|---|
| `AWS_DEPLOY_ROLE_ARN` | output `github_deploy_role_arn` |
| `HOSTED_ZONE_NAME` | `voicecraft.fr` |
| `DOMAIN_NAME` | `app.voicecraft.fr` |
| `ALERT_EMAIL` | `ops@voicecraft.fr` |
| `TF_STATE_BUCKET` | `mon-bucket-tfstate` |
| `GITHUB_REPOSITORIES` | `["mon-org/voicecraft-infra","mon-org/voicecraft-app"]` |
| `IMAGE_TAG` | dernier SHA déployé (utilisé sur un push du dépôt infra) |

Environnement `production` : reviewers obligatoires et restriction à la branche `main`.

Le rôle `github_deploy` peut seulement pousser dans ECR et lire/écrire l'état. Pour que la CI
fasse `terraform apply`, ajoutez une politique dédiée dans `github_terraform_policy_arns`.

## Points d'attention

- **4ᵉ image** : non nommée sur le schéma, `worker` par défaut (variable `ecr_repositories`).
- **Sandbox** : Fargate isole chaque tâche dans une microVM Firecracker ; pas de task role,
  filesystem en lecture seule, capabilities retirées, SG limité aux endpoints.
- **DocumentDB** : mot de passe géré dans Secrets Manager avec rotation automatique ;
  le backend doit embarquer le bundle CA `global-bundle.pem` pour TLS.
- **Shield Standard** est automatique sur l'ALB.
- **Slack** : relier le topic SNS `alerts` via Amazon Q Developer in chat applications.
- Si GuardDuty / Security Hub / Config / Inspector sont déjà gérés par AWS Organizations,
  passez les `enable_*` à `false`.
- ALB et DocumentDB ont la protection contre la suppression : la désactiver avant un destroy.
