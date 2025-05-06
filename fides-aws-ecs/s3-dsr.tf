# S3 Bucket for Data Subject Requests (DSR)
resource "aws_s3_bucket" "dsr" {
  bucket = "${var.s3_bucket_name_prefix}-dsr-${var.environment_name}"

  tags = {
    Name = "Fides DSR Storage - ${title(var.environment_name)}"
  }

  # Recommended to prevent accidental deletion of DSR data
  lifecycle {
    prevent_destroy = false # Set to true in production
  }
}

# Set ownership controls for the DSR bucket
resource "aws_s3_bucket_ownership_controls" "dsr" {
  bucket = aws_s3_bucket.dsr.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Server side encryption for the DSR bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "dsr" {
  bucket = aws_s3_bucket.dsr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Set lifecycle policy for DSR data
resource "aws_s3_bucket_lifecycle_configuration" "dsr" {
  bucket = aws_s3_bucket.dsr.id

  rule {
    id     = "dsr-data-retention"
    status = "Enabled"

    # Use filter with prefix to match all objects
    filter {
      prefix = ""
    }

    # Set appropriate retention based on your data retention policies
    expiration {
      days = 365 # Example: retain DSR data for 1 year
    }
  }
}

# Block public access to the DSR bucket (critical for privacy data)
resource "aws_s3_bucket_public_access_block" "dsr" {
  bucket = aws_s3_bucket.dsr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add CORS configuration if needed for front-end access
resource "aws_s3_bucket_cors_configuration" "dsr" {
  bucket = aws_s3_bucket.dsr.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"] # Consider restricting this in production
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Optional: Add bucket versioning for data protection
resource "aws_s3_bucket_versioning" "dsr" {
  bucket = aws_s3_bucket.dsr.id

  versioning_configuration {
    status = "Enabled"
  }
}
