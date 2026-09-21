data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

# ---------- ecs_task_execution : pull ECR, lit SSM/Secrets ----------
resource "aws_iam_role" "execution" {
  name               = "${var.name}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_secrets" {
  statement {
    actions   = ["ssm:GetParameters"]
    resources = [var.groq_api_key_arn, var.jwt_secret_arn]
  }
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.docdb_secret_arn]
  }
  statement {
    actions   = ["kms:Decrypt"]
    resources = [var.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  name   = "read-app-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_secrets.json
}

# ---------- backend_task : RunTask borné au cluster sandbox, PassRole restreint ----------
resource "aws_iam_role" "backend_task" {
  name               = "${var.name}-backend-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

data "aws_iam_policy_document" "backend_task" {
  statement {
    sid       = "RunSandboxOnly"
    actions   = ["ecs:RunTask"]
    resources = ["arn:aws:ecs:${var.region}:${var.account_id}:task-definition/${var.name}-sandbox:*"]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [aws_ecs_cluster.sandbox.arn]
    }
  }

  statement {
    sid       = "ManageSandboxTasks"
    actions   = ["ecs:StopTask", "ecs:DescribeTasks"]
    resources = ["arn:aws:ecs:${var.region}:${var.account_id}:task/${aws_ecs_cluster.sandbox.name}/*"]
  }

  statement {
    sid       = "TagOnRunTask"
    actions   = ["ecs:TagResource"]
    resources = ["arn:aws:ecs:${var.region}:${var.account_id}:task/${aws_ecs_cluster.sandbox.name}/*"]
    condition {
      test     = "StringEquals"
      variable = "ecs:CreateAction"
      values   = ["RunTask"]
    }
  }

  # La sandbox n'a pas de task role : seul le rôle d'exécution peut être passé
  statement {
    sid       = "PassExecutionRoleOnly"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.execution.arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "backend_task" {
  name   = "run-sandbox"
  role   = aws_iam_role.backend_task.id
  policy = data.aws_iam_policy_document.backend_task.json
}
