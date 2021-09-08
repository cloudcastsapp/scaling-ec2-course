###
# CodeDeploy App
##
resource "aws_codedeploy_app" "this" {
  compute_platform = "Server"
  name             = "cloudcasts-${var.infra_env}-deploy-app"

  tags = {
    Name        = "cloudcasts-${var.infra_env}-deploy-app"
    Project     = "cloudcasts.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

###
# IAM for CodeDeploy Group
##
resource "aws_iam_role" "this" {
  name = "cloudcasts-${var.infra_env}-deploy-role"

  # We only allow it to assume role for us-east-2
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.us-east-2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# AWS pre-made role, see: https://console.aws.amazon.com/iam/home#/policies/arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole$jsonEditor
# NOTE: It's better that you copy and tweak this for yourself to reduce permissions it gives, depending
#       on the features you actually use. AWS ca - and have - change their managed roles at any time without notification.
resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.this.name
}

###
# Deployment Groups
##
resource "aws_codedeploy_deployment_group" "this" {
  # Note: Creating multiple groups here
  for_each = var.deploy_groups

  app_name = aws_codedeploy_app.this.name

  deployment_group_name = "cloudcasts-${var.infra_env}-${each.key}-deploy-group"
  service_role_arn = aws_iam_role.this.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  autoscaling_groups = [each.value.asg]

  deployment_style {
    # Allow de-registering of instance from ALB target group when deploying
    deployment_option = each.value.traffic

    deployment_type = "IN_PLACE" # vs BLUE_GREEN
  }

  dynamic "load_balancer_info" {
    for_each = each.value.alb == null ? [] : [each.value.alb]
    content {
      target_group_info {
        name = load_balancer_info.value
      }
    }
  }

  tags = {
    Name        = "cloudcasts-${var.infra_env}-${each.key}-deploy-group"
    Role        = each.key
    Project     = "cloudcasts.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}