resource "aws_s3_bucket" "artifacts" {
  bucket = "cloudcasts-artifacts"
  acl    = "private"

  tags = {
    Name        = "cloudcasts - Artifacts Bucket"
    Environment = var.infra_env
    Project     = "cloudcasts"
    Role        = "build"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role" "this" {
  name = "cloudcasts-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.us-east-2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "this" {
  role = aws_iam_role.this.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.artifacts.arn}",
        "${aws_s3_bucket.artifacts.arn}/*"
      ]
    },
    {
        "Action": [
            "codedeploy:Batch*",
            "codedeploy:CreateDeployment",
            "codedeploy:Get*",
            "codedeploy:List*",
            "codedeploy:RegisterApplicationRevision"
        ],
        "Effect": "Allow",
        "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "this" {
  name = "cloudcasts-app-builder"
  description   = "Building CloudCasts Sample App"
  service_role = aws_iam_role.this.arn

  build_timeout = 15 # minutes

  # We'll define artifacts in buildspec
  artifacts {
    type = "NO_ARTIFACTS"
  }

  # Compute: https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html
  # Images: https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD" # SERVICE_ROLE if pulling a custom image

#    environment_variable {
#      name  = "SLACK_URL"
#      value = var.slack_url
#    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = "codebuild/cloudcasts"
      stream_name = "builds"
    }

//    s3_logs {
//      status = "ENABLED"
//      location = "${aws_s3_bucket.artifacts.id}/build-log"
//    }
  }

  source {
    type            = "GITHUB"
    location        = var.git_url
    git_clone_depth = 1
    report_build_status = true
  }

  tags = {
    Name        = "cloudcasts - App Builder"
    Environment = var.infra_env
    Project     = "cloudcasts"
    Role        = "build"
    ManagedBy   = "terraform"
  }
}

# note: It's not obvious but once this is created, all GitHub CodeBuild projects
#       in this region can use these credentials. We don't need to "connect" these
#       these credentials to the project ourselves
# See https://docs.aws.amazon.com/codebuild/latest/userguide/access-tokens.html
resource "aws_codebuild_source_credential" "this" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}

# See https://docs.aws.amazon.com/codebuild/latest/userguide/github-webhook.html
resource "aws_codebuild_webhook" "this" {
  project_name = aws_codebuild_project.this.name

  depends_on = [
    aws_codebuild_source_credential.this
  ]

  filter_group {
    filter {
      type = "EVENT"
      pattern = "PUSH"
    }

    # Only build tags
    # filter {
    #   type = "HEAD_REF"
    #   pattern = "refs/tags" # Optionally detect tag pattern, e.g. "refs/tags/v(.*)"
    # }
  }
}