resource "aws_autoscaling_group" "this" {
  launch_template {
    name    = aws_launch_template.launch_template.name
    version = "$Latest"
  }

  name                = "cloudcasts-${var.infra_env}-${var.infra_role}-asg"
  vpc_zone_identifier = var.asg_subnets

  min_size             = 0
  max_size             = 5
  desired_capacity     = 2
  termination_policies = ["OldestInstance"]

  health_check_type         = var.infra_role == "http" ? "ELB" : "EC2"
  health_check_grace_period = 90    # Seconds

  lifecycle {
    # see notes in https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment
    ignore_changes = [desired_capacity, load_balancers, target_group_arns]
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  count = var.infra_role == "http" ? 1 : 0

  autoscaling_group_name = aws_autoscaling_group.this.id
  alb_target_group_arn   = aws_lb_target_group.this[0].arn
}