# IAM role for Lambda
resource "aws_iam_role" "lambda_invalidate_role" {
  name = "saidoportfolio-cloudfront-invalidate-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_invalidate_policy" {
  role = aws_iam_role.lambda_invalidate_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codepipeline:PutJobSuccessResult",
          "codepipeline:PutJobFailureResult"
        ]
        Resource = "*"
      }
    ]
  })
}


data "archive_file" "invalidate_zip" {
  type        = "zip"
  source_file = "${path.module}/invalidate_cf.py"
  output_path = "${path.module}/invalidate_cf.zip"
}

resource "aws_lambda_function" "invalidate_lambda" {
  function_name = "saidoportfolio-cloudfront-invalidate"
  role          = aws_iam_role.lambda_invalidate_role.arn
  handler       = "invalidate_cf.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.invalidate_zip.output_path
  source_code_hash = filebase64sha256("${path.module}/invalidate_cf.py")

  environment {
    variables = {
      DISTRIBUTION_ID = aws_cloudfront_distribution.live_cf.id
    }
  }

  tags = {
    Project = "SaidoPortfolio"
  }
}

resource "aws_lambda_function" "invalidate_lambda_test" {
  function_name = "saidoportfolio-cloudfront-invalidate-test"
  role          = aws_iam_role.lambda_invalidate_role.arn
  handler       = "invalidate_cf.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.invalidate_zip.output_path
  source_code_hash = filebase64sha256("${path.module}/invalidate_cf.py")

  environment {
    variables = {
      DISTRIBUTION_ID = aws_cloudfront_distribution.test_cf.id
    }
  }

  tags = {
    Project = "SaidoPortfolio"
    Env     = "staging"
  }
}

