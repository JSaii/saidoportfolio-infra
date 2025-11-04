# ================CODEPIPELINE - LIVE================
# ===================================================

resource "aws_iam_role" "codepipeline_role" {
  name = "saidoportfolio-live-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*", "iam:PassRole"]
        Resource = "*"
      }
    ]
  })
}

# Artifact bucket for CodePipeline
resource "aws_s3_bucket" "artifact_live" {
  bucket = "saidoportfolio-artifacts-live"
  tags = {
    Project = "SaidoPortfolio"
    Env     = "production"
  }
}

resource "aws_codepipeline" "live_pipeline" {
  name     = "saidoportfolio-live-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_live.bucket
    type     = "S3"
  }

  # ---------- SOURCE ----------
  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = "main"
        OAuthToken = var.github_token
      }
    }
  }

  # ---------- DEPLOY ----------
  stage {
    name = "Deploy"

    action {
      name            = "DeployToS3"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        BucketName = "saidoportfolio-live"
        Extract    = "true"
      }
    }
  }
}

# ================CODEPIPELINE - TEST================
# ===================================================

resource "aws_iam_role" "codepipeline_role_test" {
  name = "saidoportfolio-test-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy_test" {
  role = aws_iam_role.codepipeline_role_test.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*", "iam:PassRole"]
        Resource = "*"
      }
    ]
  })
}

# Artifact bucket for CodePipeline
resource "aws_s3_bucket" "artifact_test" {
  bucket = "saidoportfolio-artifacts-test"
  tags = {
    Project = "SaidoPortfolio"
    Env     = "staging"
  }
}

# CodePipeline: test branch → test bucket
resource "aws_codepipeline" "test_pipeline" {
  name     = "saidoportfolio-test-pipeline"
  role_arn = aws_iam_role.codepipeline_role_test.arn

  artifact_store {
    location = aws_s3_bucket.artifact_test.bucket
    type     = "S3"
  }

  # ---------- SOURCE ----------
  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = "test"
        OAuthToken = var.github_token
      }
    }
  }

  # ---------- DEPLOY ----------
  stage {
    name = "Deploy"

    action {
      name            = "DeployToS3"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        BucketName = "saidoportfolio-test"
        Extract    = "true"
      }
    }
  }
}