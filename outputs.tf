output "live_site_url" {
  description = "Public website endpoint for the production site"
  value       = aws_s3_bucket_website_configuration.live.website_endpoint
}

output "test_site_url" {
  description = "Public website endpoint for the staging site"
  value       = aws_s3_bucket_website_configuration.test.website_endpoint
}

output "live_cloudfront_url" {
  value = aws_cloudfront_distribution.live_cf.domain_name
}

output "test_cloudfront_url" {
  value = aws_cloudfront_distribution.test_cf.domain_name
}

output "test_key_id" {
  description = "CloudFront public key ID used for signing URLs"
  value       = aws_cloudfront_public_key.test_public_key.id
}

