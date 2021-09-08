data "aws_caller_identity" "current" {}

data "template_file" "user_data_app" {
  template = file("${path.module}/scripts/user-data.tpl")

  vars = {
    infra_env  = var.infra_env
    infra_role = var.infra_role
    git_url    = var.git_url
  }
}


resource "aws_launch_template" "launch_template" {
  name_prefix            = "cloudcasts-${var.infra_env}-${var.infra_role}-"
  image_id               = var.ami
  instance_type          = var.instance_type
  user_data              = base64encode(data.template_file.user_data_app.rendered)
  key_name               = var.ssh_key_name
  vpc_security_group_ids = var.security_groups
  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  tags = merge(
    {
      Name        = "cloudcasts-${var.infra_env}-${var.infra_role}-lt"
      Role        = var.infra_role
      Project     = "cloudcasts.io"
      Environment = var.infra_env
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#tag-specifications
  tag_specifications {
    resource_type = "instance"
    tags = merge({
      Name        = "cloudcasts-${var.infra_env}-${var.infra_role}-instance"
      Role        = var.infra_role
      Project     = "cloudcasts.io"
      Environment = var.infra_env
      ManagedBy   = "terraform"
    }, var.instance_tags)
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge({
      Name        = "cloudcasts-${var.infra_env}-${var.infra_role}-volume"
      Role        = var.infra_role
      Project     = "cloudcasts.io"
      Environment = var.infra_env
      ManagedBy   = "terraform"
    }, var.volume_tags)
  }
}

resource "aws_iam_role" "this" {
  name = "cloudcasts-${var.infra_env}-${var.infra_role}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "this" {
  name = "cloudcasts-${var.infra_env}-${var.infra_role}-policy"
  role = aws_iam_role.this.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${var.artifact_bucket}",
        "${var.artifact_bucket}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter"
      ],
      "Resource": "arn:aws:ssm:us-east-2:${data.aws_caller_identity.current.account_id}:parameter/cloudcasts/${var.infra_env}/*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = "cloudcasts-${var.infra_env}-${var.infra_role}-profile"

  role = aws_iam_role.this.name
}