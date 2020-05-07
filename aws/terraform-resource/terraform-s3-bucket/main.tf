provider "aws" {
  region = var.region
}

data "aws_caller_identity" "my_account" {
}

resource "aws_s3_bucket" "my_bucket_tf" {
  bucket = "tf-neo-s3-bucket-${data.aws_caller_identity.my_account.account_id}"
  region = var.region
  acl = "public-read"
  versioning {
    enabled = false
  }

  lifecycle_rule {
    prefix = "files/"
    enabled = true
    noncurrent_version_transition {
      days = 30
      storage_class = "STANDARD_IA"
    }
    noncurrent_version_transition {
      days = 60
      storage_class = "GLACIER"
    }
    noncurrent_version_expiration {
      days = 61
    }
  }
  tags = {
    Type = "LOG"
    Tier = "STANDARD"
    Role = "Demo"
  }
}

resource "aws_s3_bucket_policy" "my_bucket_policy_tf" {
  bucket = aws_s3_bucket.my_bucket_tf.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "myBucketPolicy",
  "Statement": [
    {
      "Sid": "IPAllow",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.my_bucket_tf.bucket}/*",
      "Condition": {
         "IpAddress": {"aws:SourceIp": "8.8.8.8/32"}
      }
    }
  ]
}
POLICY
//  policy = <<POLICY
//  {
//    "Version": "2012-10-17",
//    "Id": "myBucketPolicy",
//    "Statement": [
//      {
//          "Sid": "IPAllow",
//          "Effect": "Deny",
//          "Principal": "*",
//          "Action": "s3.*",
//          "Resource": "arn:aws:s3:::${aws_s3_bucket.my_bucket_tf.bucket}/*"
//                "Condition": {
//         "IpAddress": {"aws:SourceIp": "8.8.8.8/32"}
//      }
//      }
//    ]
//  }
//  POLICY
}

resource "aws_s3_bucket_object" "readme_file" {
  bucket = aws_s3_bucket.my_bucket_tf.bucket
  key = "files/readme.txt"
  source = "readme.txt"
  etag = filemd5("readme.txt")
}