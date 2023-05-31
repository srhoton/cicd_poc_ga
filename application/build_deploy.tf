resource "aws_codestarconnections_connection" "cicd_poc" {
  name          = "cicd-poc"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "cicd_poc_srhoton_artifact_bucket" {
  bucket        = "cicd-poc-srhoton-artifact-bucket"
  force_destroy = true
}

data "aws_iam_policy_document" "cicd_poc_assume_by_pipeline" {
  statement {
    sid     = "AllowAssumeByPipeline"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cicd_poc_pipeline_role" {
  name               = "cicd-poc-pipeline-role"
  assume_role_policy = data.aws_iam_policy_document.cicd_poc_assume_by_pipeline.json
}

data "aws_iam_policy_document" "cicd_poc_pipeline" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.cicd_poc_srhoton_artifact_bucket.arn}",
      "${aws_s3_bucket.cicd_poc_srhoton_artifact_bucket.arn}/*",
    ]
  }

  statement {
    sid    = "AllowCodeBuild"
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowCodeDeploy"
    effect = "Allow"

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
      "ecr:DescribeImages",
      "codestar-connections:*",
      "appconfig:StartDeployment",
      "appconfig:GetDeployment",
      "appconfig:StopDeployment",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowECS"
    effect = "Allow"

    actions = ["ecs:*"]

    resources = ["*"]
  }

  statement {
    sid    = "AllowPassRole"
    effect = "Allow"

    resources = ["*"]

    actions = ["iam:PassRole"]

    condition {
      test     = "StringLike"
      values   = ["ecs-tasks.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }
}

resource "aws_iam_role" "cicd_poc_codebuild" {
  name               = "cicd-poc-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.cicd_poc_assume_by_pipeline.json
}

data "aws_iam_policy_document" "cicd_poc_codebuild" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.cicd_poc_srhoton_artifact_bucket.arn}",
      "${aws_s3_bucket.cicd_poc_srhoton_artifact_bucket.arn}/*",
    ]
  }

  statement {
    sid    = "AllowECRAuth"
    effect = "Allow"

    actions = ["ecr:GetAuthorizationToken"]

    resources = ["*"]
  }

  statement {
    sid    = "AllowECRUpload"
    effect = "Allow"

    actions = [
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",

    ]

    resources = [aws_ecr_repository.cicd_poc.arn]
  }

  statement {
    sid       = "AllowECSDescribeTaskDefinition"
    effect    = "Allow"
    actions   = ["ecs:DescribeTaskDefinition"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  role   = aws_iam_role.cicd_poc_codebuild.name
  policy = data.aws_iam_policy_document.cicd_poc_codebuild.json
}

resource "aws_iam_role_policy" "codepipeline" {
  role   = aws_iam_role.cicd_poc_pipeline_role.name
  policy = data.aws_iam_policy_document.cicd_poc_pipeline.json
}

#resource "aws_codebuild_project" "cicd_poc" {
#  name         = "example-codebuild"
#  description  = "Codebuild for the ECS Example app"
#  service_role = aws_iam_role.cicd_poc_codebuild.arn
#
#  artifacts {
#    type = "CODEPIPELINE"
#  }
#
#  environment {
#    compute_type    = "BUILD_GENERAL1_SMALL"
#    image           = "aws/codebuild/standard:7.0"
#    type            = "LINUX_CONTAINER"
#    privileged_mode = true
#
#    environment_variable {
#      name  = "REPOSITORY_URI"
#      value = aws_ecr_repository.cicd_poc.repository_url
#    }
#
#    environment_variable {
#      name  = "TASK_DEFINITION"
#      value = "arn:aws:ecs:us-west-2:${var.account_id}:task-definition/${aws_ecs_task_definition.cicd_poc_task_definition.family}"
#    }
#
#    environment_variable {
#      name  = "CONTAINER_NAME"
#      value = var.container_name
#    }
#
#    environment_variable {
#      name  = "SUBNET_1"
#      value = data.aws_subnet.public_1.id
#    }
#
#    environment_variable {
#      name  = "SUBNET_2"
#      value = data.aws_subnet.public_2.id
#    }
#
#    environment_variable {
#      name  = "SUBNET_3"
#      value = data.aws_subnet.public_3.id
#    }
#
#    environment_variable {
#      name  = "SECURITY_GROUP"
#      value = aws_security_group.cicd_poc_ecs_service.id
#    }
#  }
#
#  source {
#    type = "CODEPIPELINE"
#  }
#}

data "aws_iam_policy_document" "cicd_poc_assume_by_codedeploy" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "cicd_poc_codedeploy" {
  name               = "cicd_poc_codedeploy"
  assume_role_policy = data.aws_iam_policy_document.cicd_poc_assume_by_codedeploy.json
}

data "aws_iam_policy_document" "cicd_poc_codedeploy" {
  statement {
    sid    = "AllowLoadBalancingAndECSModifications"
    effect = "Allow"

    actions = [
      "ecs:CreateTaskSet",
      "ecs:DeleteTaskSet",
      "ecs:DescribeServices",
      "ecs:UpdateServicePrimaryTaskSet",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",
      "codestar-connections:*",
      "appconfig:StartDeployment",
      "appconfig:GetDeployment",
      "appconfig:StopDeployment",
      "codecommit:GetRepository"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowS3"
    effect = "Allow"

    actions = ["s3:GetObject"]

    resources = [aws_s3_bucket.cicd_poc_srhoton_artifact_bucket.arn]
  }

  statement {
    sid    = "AllowPassRole"
    effect = "Allow"

    actions = ["iam:PassRole"]

    resources = [
      aws_iam_role.cicd_poc_execution_role.arn,
      aws_iam_role.cicd_poc_task_role.arn
    ]
  }
}

resource "aws_iam_role_policy" "cicd_poc_codedeploy" {
  role   = aws_iam_role.cicd_poc_codedeploy.name
  policy = data.aws_iam_policy_document.cicd_poc_codedeploy.json
}

resource "aws_codedeploy_app" "cicd_poc" {
  compute_platform = "ECS"
  name             = "cicd-poc"
}

resource "aws_codedeploy_deployment_group" "cicd_poc" {
  app_name = aws_codedeploy_app.cicd_poc.name
  deployment_group_name = "cicd-poc"
  service_role_arn = aws_iam_role.cicd_poc_codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events = ["DEPLOYMENT_FAILURE"]
  }
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }  
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.cicd_poc_listener.arn]
      }

      target_group {
        name = "${aws_lb_target_group.cicd_poc_target_group_one.name}"
      }

      target_group {
        name = "${aws_lb_target_group.cicd_poc_target_group_two.name}"
      }
    }
  }
  ecs_service {
    cluster_name = aws_ecs_cluster.cicd_poc.name
    service_name = aws_ecs_service.cicd_poc_service.name
  }
}

resource "aws_codepipeline" "cicd_poc" {
  name     = "cicd-poc-pipeline"
  role_arn = aws_iam_role.cicd_poc_pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.cicd_poc_srhoton_artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name = "Image"
      category = "Source"
      owner    = "AWS"
      provider = "ECR"
      version  = "1"
      input_artifacts = []
      output_artifacts = [ "SourceArtifact" ]
      configuration = {
        RepositoryName = "cicd-poc"
        ImageTag       = "latest"
      }
    }    
  }

  #  stage {
  #  name = "Build"
  #
  #  action {
  #    name             = "Build"
  #    category         = "Build"
  #    owner            = "AWS"
  #    provider         = "CodeBuild"
  #    version          = "1"
  #    input_artifacts  = ["source"]
  #    output_artifacts = ["build"]
  #
  #    configuration = {
  #      ProjectName = "${aws_codebuild_project.cicd_poc.name}"
  #    }
  #  }
  #}
  stage {
    name = "Approve"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        #NotificationArn = "${var.approve_sns_arn}"
        #CustomData = "${var.approve_comment}"
        #ExternalEntityLink = "${var.approve_url}"
      }
    }
  }
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["SourceArtifact"]

      configuration = {
        ClusterName        = aws_ecs_cluster.cicd_poc.name
        ServiceName        = aws_ecs_service.cicd_poc_service.name
        FileName           = "imagedefinitions.json"
      }
    }
  }
}
