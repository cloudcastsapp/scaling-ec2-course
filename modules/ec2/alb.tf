resource "aws_lb" "this" {
  count = var.infra_role == "http" ? 1 : 0

  name               = "cloudcasts-${var.infra_env}-${var.infra_role}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = var.security_groups
  subnets         = var.alb_subnets

  tags = {
    Name        = "cloudcasts-${var.infra_env}-${var.infra_role}-alb"
    Role        = var.infra_role
    Project     = "cloudcasts.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_target_group" "this" {
  count = var.infra_role == "http" ? 1 : 0

  name                 = "cloudcasts-${var.infra_env}-${var.infra_role}-alb-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30
  health_check {
    interval = 10
    matcher  = "200-299"
    path     = "/"
  }

  tags = {
    Name        = "cloudcasts-${var.infra_env}-${var.infra_role}-alb-tg"
    Role        = var.infra_role
    Project     = "cloudcasts.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_listener" "this" {
  count = var.infra_role == "http" ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  tags = {
    Name        = "cloudcasts-${var.infra_env}-${var.infra_role}-alb-listener"
    Role        = var.infra_role
    Project     = "cloudcasts.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}