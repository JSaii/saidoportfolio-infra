# ================LIVE BUCKET================
# ===========================================
resource "aws_s3_bucket" "live" {
  bucket = "saidoportfolio-live-us"

  tags = {
    Name = "saidoportfolio-live"
    Env  = "production"
  }
}
resource "aws_s3_bucket_public_access_block" "live" {
  bucket = aws_s3_bucket.live.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "live" {
  bucket = aws_s3_bucket.live.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "live" {
  bucket = aws_s3_bucket.live.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.live.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.live_cf.arn
          }
        }
      }
    ]
  })
}

# ================TEST BUCKET================
# ===========================================
resource "aws_s3_bucket" "test" {
  bucket = "saidoportfolio-test-us"

  tags = {
    Name = "saidoportfolio-test"
    Env  = "staging"
  }
}

resource "aws_s3_bucket_public_access_block" "test" {
  bucket = aws_s3_bucket.test.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "test" {
  bucket = aws_s3_bucket.test.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "test" {
  bucket = aws_s3_bucket.test.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.test.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.test_cf.arn
          }
        }
      }
    ]
  })
}