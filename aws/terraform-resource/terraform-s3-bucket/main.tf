provider "aws" {
  region = var.region
}

data "aws_caller_identity" "my_account" {
}

resource "aws_s3_bucket" "my_bucket_tf" {
  bucket = "tf-neo-s3-bucket-${data.aws_caller_identity.my_account.account_id}"
  region = var.region
  versioning {
    enabled = true
  }
  tags = {
    Type = "LOG"
    Tier = "STANDARD"
    Role = "Demo"
  }
}

resource "aws_s3_bucket_object" "readme_file" {
  bucket = aws_s3_bucket.my_bucket_tf.bucket
  key = "files/readme.txt"
  source = "readme.txt"
  etag = filemd5("readme.txt")
}