resource "aws_ecr_repository" "cicd_poc" {
  name = "cicd-poc"
}

data "aws_iam_policy_document" "cicd_poc_ecr_policy" {
  statement {
    sid    = "cicd_poc_ecr_policy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.account_id]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}

resource "aws_ecr_repository_policy" "cicd_poc_ecr_repo_policy" {
  repository = aws_ecr_repository.cicd_poc.name
  policy     = data.aws_iam_policy_document.cicd_poc_ecr_policy.json
}
