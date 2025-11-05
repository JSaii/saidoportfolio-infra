# ================CLOUDFRONT LIVE================
# ===============================================

resource "aws_cloudfront_origin_access_control" "live_oac" {
  name                              = "saidoportfolio-live-oac"
  description                       = "OAC for CloudFront to access live S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "live_cf" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.live.bucket_regional_domain_name
    origin_id                = "live-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.live_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "live-s3-origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"
  is_ipv6_enabled = true
  aliases          = ["josephsaido.com", "www.josephsaido.com"]

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:415708912593:certificate/d0877a42-ffc2-44cc-a912-953c07459528"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Project = "SaidoPortfolio"
    Env     = "production"
  }
}

# ================CLOUDFRONT TEST================
# ===============================================
resource "aws_cloudfront_origin_access_control" "test_oac" {
  name                              = "saidoportfolio-test-oac"
  description                       = "OAC for CloudFront to access test S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ---------- PUBLIC KEY ----------
resource "aws_cloudfront_public_key" "test_public_key" {
  name        = "saidoportfolio-test-public-key"
  comment     = "Public key for signed URLs on test.josephsaido.com"
  encoded_key = file("${path.module}/public_key.pem")
}

# ---------- KEY GROUP ----------
resource "aws_cloudfront_key_group" "test_key_group" {
  name  = "saidoportfolio-test-key-group"
  items = [aws_cloudfront_public_key.test_public_key.id]
}

resource "aws_cloudfront_distribution" "test_cf" {
  enabled             = true
  default_root_object = "index.html"

  depends_on = [
  aws_cloudfront_key_group.test_key_group
  ]

  origin {
    domain_name              = aws_s3_bucket.test.bucket_regional_domain_name
    origin_id                = "test-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.test_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "test-s3-origin"

    viewer_protocol_policy = "redirect-to-https"
    trusted_key_groups = [aws_cloudfront_key_group.test_key_group.id]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class      = "PriceClass_100"
  is_ipv6_enabled  = true

  aliases = ["test.josephsaido.com"]

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:415708912593:certificate/d0877a42-ffc2-44cc-a912-953c07459528"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Project = "SaidoPortfolio"
    Env     = "staging"
  }
}
