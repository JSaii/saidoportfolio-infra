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

  viewer_certificate {
    cloudfront_default_certificate = true
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