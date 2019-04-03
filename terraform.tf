terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_ecs_cluster" "goryudyuma-test-cluster" {
  name = "goryudyuma-test-cluster"
}

resource "aws_codebuild_project" "goryudyuma-auto-terraform" {
  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "hashicorp/terraform:0.11.13"
    type         = "LINUX_CONTAINER"
  }

  name         = "goryudyuma-auto-terraform"
  service_role = "${aws_iam_role.goryudyuma-auto-terraform-service-role.arn}"

  source {
    type            = "GITHUB"
    location        = "https://github.com/Goryudyuma/terraform-auto-recreate-test.git"
    buildspec       = "buildspec.yml"
    git_clone_depth = 1
  }
}

resource "aws_iam_role" "goryudyuma-auto-terraform-service-role" {
  name               = "codebuild-goryudyuma-auto-terraform-service-role"
  assume_role_policy = "${data.aws_iam_policy_document.goryudyuma-auto-terraform-service-role.json}"
  path               = "/service-role/"
}

data "aws_iam_policy_document" "goryudyuma-auto-terraform-service-role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      identifiers = [
        "codebuild.amazonaws.com",
      ]

      type = "Service"
    }
  }
}

resource "aws_iam_role_policy" "goryudyuma-auto-terraform-service-role-policy" {
  policy = "${data.aws_iam_policy_document.goryudyuma-auto-terraform-service-role-policy.json}"
  role   = "${aws_iam_role.goryudyuma-auto-terraform-service-role.id}"
}

data "aws_iam_policy_document" "goryudyuma-auto-terraform-service-role-policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:*",
    ]

    resources = ["*"]
  }
}
